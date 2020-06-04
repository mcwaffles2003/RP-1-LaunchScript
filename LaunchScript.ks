//Functional Launch script

main().

function main{
  PreScript().
  findTaggedParts().
  engineCheck(allEngines).
  doTitle().
  doCountdown().
  doLaunch().
  ascentLoop().
//  doCircularize().
//  executeManeuver(maneuverTime, nodeX, nodeY, nodeZ).
  print("It Worked!!!!!").
wait until Ag1.                        //hold program open
}

function PreScript{
  global currentEngineNumber is 1.
  global currentTankNumber is 1.
}


function ascentLoop{
  print ("Current stage :  " + stage:number) at (0,8).
  print ("Resource:                Current:     %:") at (0,12).
  print ("----------------------------------------") at (0,13).
  doAscent().
  until ascentDone{
    showUI().
    newSmartStage().  
  }
  doShutDown().
}


//--------------Launch Ascent Stuff----------------------------------------------
function doTitle{
  clearscreen.
  print("Press 0 to begin countdown.").
  print("Press 9 to shut down program.").
  print(" ").
  print("Before launching make sure all tags and stages are placed appropriately").
  print(" ").
  print("Engines should be tagged 'Engine #' where # is the order of engines fired from 1 and up").
  print(" ").
  print("Tanks should be labeled 'Tanks #' where # should match the corresponding engine").
  print(" ").
  print("All ullage motors should be tagged 'ullage motor'").
  print(" ").
  print("Ullage stages are in the format:").
  print("Separation->Ullage motor->Ignite next engine->seperate ullage motors").
  print(" ").
  print("Hot stages are in the order:").
  print("Ignite engine->Separation").
  on Ag9{                                    // press 9 to shutdown
    shutdown.
  }
  wait until Ag10.                           // Start sequence
  clearscreen.
  lock throttle to 1.
  set ascentDone to false.
  return ascentDone.
}

function doCountdown{ 
  local count is 10.
  print ("Countdown: ") at (0,0).
  until count = 0 {
    if count = 3{
      stage.//Ignite main engines
      print("Ignition!") at (0,1).
    }
    print ("T-" + count +" ") at (10,0).
    set count to (count-1).
    wait 1.
  }

}

function doLaunch{
  print ("Lift Off!") at (0,2).
  Stage.//Release launch clamps
}

function doAscent{
  print("Starting Ascent") at (0,3).
  lock targetPitch to   3.47972E-9 * alt:radar^2 - 0.00110814 * alt:radar + 89.8439.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).
  when apoapsis>300000 then{
    set ascentDone to true.
  }
  fuelCheck(allTanks).
}

function doCircularization{
  //ToDo
}

function doShutDown{
  set ascentDone to true.
  lock throttle to 0.
  print ("Shut down.").
  lock steering to prograde.
  wait until false.
  return ascentDone.
}

function showUI{
  list resources in reslist.
  // print ("Current stage :  " + stage:number) at (0,8).
  // print ("Resource:                Current:     %:") at (0,12).
  // print ("----------------------------------------") at (0,13).
  showResources().
}






//-----------------Fuel Monitoring system------------------------------------


function showResources{
  local count is 14.
  for res in reslist {
    LOCAL printString IS res:name:PADRIGHT(25).
    SET printString TO (printString + (round(res:amount,2))):PADRIGHT(38).
    SET printString TO printString + (round(100*res:amount/res:capacity)).
    PRINT printString at (0,count).
    set count to count + 1.
  }
}

function findTaggedParts{
  global allEngines is ship:PARTSTAGGEDPATTERN("Engine").
  global allTanks is ship:PARTSTAGGEDPATTERN("Tank").
  global allUllage is ship:PARTSTAGGEDPATTERN("Ullage").
}


//-------------------------New staging system-------------------

function checkForUllageMotor{
  parameter allUllage.
  set ullageMotorsNextStage to false.
  for part in allUllage{
    if part:stage = stage:number-2{
      set ullageMotorsNextStage to true.
    }
    else{
      set ullageMotorsNextStage to false.
    }
  }
  return ullageMotorsNextStage.
}



function fuelCheck{
  parameter allTanks.
  for part in allTanks{
    if part:tag:contains("Tank ":insert(5,currentTankNumber:tostring)){
      set currentFuelInStage to part:resources[0]:amount.
    }
  }
  print ("Current fuel:  " + currentFuelInStage) at (0,33).
  return currentFuelInStage.
}

function engineCheck{
  parameter allEngines.
  for part in allEngines{
    if part:tag:contains("Engine ":insert(7,currentEngineNumber:tostring)){
      global currentEngine is part.
    }
  }
  return currentEngine.
}

function findTimeToBurnout{
  wait 0.
  local initialFuel is fuelCheck(allTanks).            //1st check fuel
  local initialTime is TIME:SECONDS.                   //1st time check
  wait 0.1.
  local finalFuel is fuelCheck(allTanks).              //2nd check fuel
  local finalTime is TIME:SECONDS.                     //2nd time check
  local deltaTime is finalTime - initialTime.            //find change in time
  local deltaFuel is initialFuel - finalFuel.            //find change in fuel
  set timeToBurnout to finalFuel*deltaTime/deltaFuel.
  print ("Time to burn out:  " + timeToBurnout) at (0,30).
  return timeToBurnout.
}

function doHotStage{
  parameter timeToBurnout.
  print("hot staging!") at (0,7).
    stage. //Starts Engine
    until currentEngine:flameout = true.
    stage. //Separation
    postStageCheck().
}

function doUllageStage{
  parameter timeToBurnout.
  print("ullage staging!") at (0,7).
  until currentEngine:flameout = true.
  wait until stage:ready.
  Stage.                                    //Separates previous stage
  wait until stage:ready.
  Stage.                                    //Fire ullage motors
  wait until stage:ready.                   // and nextStageFuelSettled = true.
  Stage.                                    //Fire liquid fuel stage
  wait 3.                                   //wait for ullage burnout
  stage.
  postStageCheck().
}

function postStageCheck{
  clearscreen.
  set currentTankNumber to currentTankNumber + 1.
  set currentEngineNumber to currentEngineNumber + 1.
  findTaggedParts().
  checkForUllageMotor(allUllage).
  print checkForUllageMotor(allUllage) at (0,25).
  print engineCheck(allEngines) at (0,27).
  print ("current engine:  " + currentEngineNumber) at (0,28).
  print ("current tank:  " + currentTankNumber) at (0,26).
  print ("Current stage :  " + stage:number) at (0,8).
  print ("Resource:                Current:     %:") at (0,12).
  print ("----------------------------------------") at (0,13).
  wait 2.
}

function newSmartStage{
  set ullageMotorsNextStage to checkForUllageMotor(allUllage).
  engineCheck(allEngines).
  fuelCheck(allTanks).
  print ("current engine:  " + currentEngineNumber) at (0,28).
  print ("current tank:  " + currentTankNumber) at (0,26).
  findTimeToBurnout().
  if ullageMotorsNextStage = false{
    print "hotstage" at (0,38).
  }
  else{
    print "ullage stage" at (0,38).
  }
  if timeToBurnout <= 3.2{
    if ullageMotorsNextStage = false{
      doHotStage(timeToBurnout).
      }

    if ullageMotorsNextStage = true{
      doUllageStage(timeToBurnout).
    }
  }
}



//--------------Maneuvering Stuff--------------------------------------

function executeManeuver{
  parameter utime, radial, normal, prograde.
  local mnv is node(utime, radial, normal, prograde).
  addManeuverToFlightPlan(mnv).
  local startTime is calculateStartTime(mnv).
  wait until time:seconds > (startTime - 10).
  lockSteeringAtManeuverTarget(mnv).
  wait until time:seconds > startTime.
  lock throttle to 1.
  wait until isManeuverComplete(mnv).
  lock throttle to 0.
  removeManeuverFromFlightPlan(mnv).
}

function addManeuverToFlightPlan{
  parameter mnv.
  //ToDo
}

function calculateStartTime{
  parameter mnv.
  //ToDo
  return 0.
}

function lockSteeringAtManeuverTarget{
  parameter mnv.
  //ToDo
}

function isManeuverComplete{
  parameter mnv.
  //ToDo
  return true.
}

function removeManeuverFromFlightPlan{
  parameter mnv.
  //ToDo
}
