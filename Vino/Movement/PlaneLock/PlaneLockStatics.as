import Vino.Movement.Components.MovementComponent;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;
import Vino.Movement.PlaneLock.LockCharacterToPlaneCapability;
import Vino.Movement.PlaneLock.MovementDirectionPlaneInputCapability;

UFUNCTION(Category = "Movement|PlaneLock")
void StartPlaneLockMovement(AHazeActor Actor, FPlaneConstraintSettings Settings)
{
	if (!devEnsure(Settings.IsValid(), "Tried to StartPlaneLockMovement with invalid settings. Make sure you have a valid plane normal."))
		return;

	auto PlaneLockComp = UPlaneLockUserComponent::GetOrCreate(Actor);
   	if (!devEnsure(!PlaneLockComp.IsActiveltyConstraining(), "Trying to start a plane lock when there one already active. Use StopPlaneLockMovement first!"))
		StopPlaneLockMovement(Actor);

	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
	if (Player != nullptr)
	    Player.AddCapability(UMovementDirectionPlaneInputCapability::StaticClass());

	Actor.AddCapability(ULockCharacterToPlaneCapability::StaticClass());
	PlaneLockComp.LockOwnerToPlane(Settings);
}

UFUNCTION(Category = "Movement|PlaneLock")
void StartPlaneLockMovementWithLerp(AHazeActor Actor, FPlaneConstraintSettings Settings, float LerpTime)
{
	if (!devEnsure(Settings.IsValid(), "Tried to StartPlaneLockMovement with invalid settings. Make sure you have a valid plane normal."))
		return;

	auto PlaneLockComp = UPlaneLockUserComponent::GetOrCreate(Actor);
   	if (!devEnsure(!PlaneLockComp.IsActiveltyConstraining(), "Trying to start a plane lock when there one already active. Use StopPlaneLockMovement first!"))
		StopPlaneLockMovement(Actor);

	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
	if (Player != nullptr)
	{
		Player.RootOffsetComponent.FreezeAndResetWithTime(LerpTime);
		Player.AddCapability(UMovementDirectionPlaneInputCapability::StaticClass());
	}

	Actor.AddCapability(ULockCharacterToPlaneCapability::StaticClass());
		
	PlaneLockComp.LockOwnerToPlane(Settings);
}


UFUNCTION(Category = "Movement|PlaneLock")
void StartPlaneLockMovementWithSpeed(AHazeActor Actor, FPlaneConstraintSettings Settings, float LocationLerpSpeed, float RotationLerpSpeed)
{
	if (!devEnsure(Settings.IsValid(), "Tried to StartPlaneLockMovement with invalid settings. Make sure you have a valid plane normal."))
		return;

	auto PlaneLockComp = UPlaneLockUserComponent::GetOrCreate(Actor);
   	if (!devEnsure(!PlaneLockComp.IsActiveltyConstraining(), "Trying to start a plane lock when there one already active. Use StopPlaneLockMovement first!"))
		StopPlaneLockMovement(Actor);

	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
	if (Player != nullptr)
	{
		Player.RootOffsetComponent.FreezeAndResetWithSpeed(LocationLerpSpeed, RotationLerpSpeed);
	    Player.AddCapability(UMovementDirectionPlaneInputCapability::StaticClass());
	}

	Actor.AddCapability(ULockCharacterToPlaneCapability::StaticClass());
	PlaneLockComp.LockOwnerToPlane(Settings);
}



UFUNCTION(Category = "Movement|PlaneLock")
void StopPlaneLockMovement(AHazeActor Actor)
{
	if (Actor == nullptr)
		return;

	auto PlaneLockComp = UPlaneLockUserComponent::Get(Actor);
	if (!devEnsure(PlaneLockComp != nullptr, "Ending a plane lock with no plane lock component (i.e. have never started plane lock)"))
		return;

	if (PlaneLockComp.bWasReset)
		return;

	if (!devEnsure(PlaneLockComp.IsActiveltyConstraining(), "Trying to end plane lock when there is no active plane lock!"))
		return;

	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
	if (Player != nullptr)	
	    Player.AddCapability(UMovementDirectionPlaneInputCapability::StaticClass());

	PlaneLockComp.StopLocking();
}
