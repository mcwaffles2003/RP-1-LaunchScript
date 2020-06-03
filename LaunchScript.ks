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
  print("It Works!!!!!").
wait until Ag1.                        //hold program open
}

function PreScript{
  declare global currentEngineNumber to 1.
}


function ascentLoop{
  doAscent().
  until ascentDone{
    newSmartStage().
    showUI().
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
  print("Tanks should be labeled 'Tanks #' where number should match the corresponding engine").
  print(" ").
  print("All ullage motors should be tagged 'ullage motor'").
  print(" ").
  print("Ullage stages are in the format 'Separation' -> 'Ullage motor' -> 'Ignite next engine' -> 'seperate ullage motors'").
  print(" ").
  print("Hot stages are in the order 'Ignite engine' -> 'Separation'").
  print(" ").
  print("Only one action per stage!").
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
  when apoapsis>160000 then{
    set ascentDone to true.
  }
  return ascentDone.
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
  getResources().
  print ("Current stage :  " + stage:number) at (0,8).
  print ("Resource:                Current:     %:") at (0,12).
  print ("----------------------------------------") at (0,13).
  showResources(reslist,currentFuelInStage).
}






//-----------------Fuel Monitoring system------------------------------------


function getResources{
  list resources in reslist.
  return reslist.
}

function showResources{
  parameter reslist, currentFuelInStage.
  local count is 0.
  for res in reslist {
      print (res:name) at (0,14+count).
      print (round(res:amount,2)) at (25,14+count).
      print (round(100*res:amount/res:capacity)) at (38,14+count).
    set count to count + 1.
  }
}

function findTaggedParts{
  global allParts is ship:parts.
  global allEngines is list().
  global allTanks is list().
  global allUllage is list().
  for part in allParts{
    if part:tag:contains("Engine"){
      allEngines:add(part).
    }
    if part:tag:contains("Tank"){
      allTanks:add(part).
    }
    if part:tag:contains("ullage"){
      allUllage:add(part).
    }
  }
  return allTanks.
  return allEngines.
  return allUllage.
}


//-------------------------New staging system-------------------

function checkForUllageMotor{
  parameter allUllage.
  for part in allUllage{
    if part:tag = "ullage" and part:stage = stage:number-2{
      set ullageMotorsNextStage to true.
      return ullageMotorsNextStage.
    }
  }
}



function fuelCheck{
  parameter allTanks.
  if not(defined currentTank) {
    declare global currentTank to 1.
  }
  for part in allTanks{
    if part:tag:contains("Tank ":insert(5,currentTank:tostring)){
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
      print part at (0,25).
      global currentEngine is part.
    }
  }
  return currentEngine.
}

function findTimeToBurnout{
  wait 0.
  local initialTime is TIME:SECONDS.                   //1st time check
  local initialFuel is fuelCheck(allTanks).            //1st check fuel
  wait 0.1.
  local finalTime is TIME:SECONDS.                     //2nd time check
  local finalFuel is fuelCheck(allTanks).              //2nd check fuel
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
//  }
//  when timeToBurnout <= 0.2 then{ should make staged engine cutoff trigger
    wait 2.5.
    stage. //Separation
    findTaggedParts().
    checkForUllageMotor(allUllage).
    set currentTank to currentTank + 1.
    set currentEngineNumber to currentEngineNumber + 1.
    engineCheck(allEngines).
    wait 2.
    return currentTank.
    return currentEngineNumber.
//  }
}

function doUllageStage{
  parameter timeToBurnout,currentEngine.
  print("ullage staging!") at (0,7).
    when currentEngine:flameout = true then{
//    when timeToBurnout<0.1 then{
    wait until stage:ready.
    Stage.                                    //Separates previous stage
    wait until stage:ready.
    Stage.                                    //Fire ullage motors
    wait until stage:ready.// and nextStageFuelSettled = true.
    Stage.                                    //Fire liquid fuel stage
    wait 1.5.  //wait for ullage burnout
    stage.
    findTaggedParts().
    checkForUllageMotor(allUllage).
    set currentTank to currentTank + 1.
    set currentEngineNumber to currentEngineNumber + 1.
    engineCheck(allEngines).
    wait 2.
    return currentTank.
    return currentEngineNumber.
  }
}

function newSmartStage{
  set ullageMotorsNextStage to checkForUllageMotor(allUllage).
  findTimeToBurnout().
  engineCheck(allEngines).
  print currentEngine at (0,26).
  if ullageMotorsNextStage = false{
    print "hotstage" at (0,38).
  }
  else{
    print "ullage stage" at (0,38).
  }
  print ("current engine:  " + currentEngineNumber) at (0,28).
  when timeToBurnout <= 3.2 then{
    if ullageMotorsNextStage = false{
      doHotStage(timeToBurnout).
      }

    if ullageMotorsNextStage = true{
      doUllageStage(timeToBurnout,currentEngine).
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
