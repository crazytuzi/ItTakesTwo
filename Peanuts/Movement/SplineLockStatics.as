import Vino.Movement.Capabilities.Input.MovementDirectionSplineInputCapability;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.SplineLock.SplineLockComponent;
import Peanuts.Movement.MovementSplineDistantLockCapability;


UFUNCTION(Category = "Movement|SplineLock")
void StartSplineLockMovement(AHazePlayerCharacter Player, FConstraintSettings Settings)
{
	auto SplineLockComp = USplineLockComponent::GetOrCreate(Player);

	if (SplineLockComp.ActiveLockType != ESplineLockType::None)
	{
		devEnsure(false, "Trying to lock " + Player.Name + " to " + Settings.SplineToLockMovementTo.Outer.Name + " but " + Player.Name + " is already locked to: " + SplineLockComp.Constrainer.SplineToLockMovementTo.Outer.Name);
		return;
	}

    Player.AddCapability(UMovementDirectionSplineInputCapability::StaticClass());
	// We assume the player already has the splinelock capability on them.

	SplineLockComp.LockOwnerToSpline(Settings);	
}

UFUNCTION(Category = "Movement|SplineLock")
void StartSplineLockMovementWithLerp(AHazePlayerCharacter Player, FConstraintSettings Settings, float LerpTime = 0.5f)
{
	auto SplineLockComp = USplineLockComponent::GetOrCreate(Player);

	if (SplineLockComp.ActiveLockType != ESplineLockType::None)
	{
		devEnsure(false, "Trying to lock " + Player.Name + " to " + Settings.SplineToLockMovementTo.Outer.Name + " but " + Player.Name + " is already locked to: " + SplineLockComp.Constrainer.SplineToLockMovementTo.Outer.Name);
		return;
	}

	Player.RootOffsetComponent.FreezeAndResetWithTime(LerpTime);

    Player.AddCapability(UMovementDirectionSplineInputCapability::StaticClass());
	// We assume the player already has the splinelock capability on them.

	SplineLockComp.LockOwnerToSpline(Settings);	
}

UFUNCTION(Category = "Movement|SplineLock")
void StartSplineLockMovementWithSpeed(AHazePlayerCharacter Player, FConstraintSettings Settings, float LocationLerpSpeed = 800.f, float RotationLerpSpeed = 5.f)
{
	auto SplineLockComp = USplineLockComponent::GetOrCreate(Player);

	if (SplineLockComp.ActiveLockType != ESplineLockType::None)
	{
		devEnsure(false, "Trying to lock " + Player.Name + " to " + Settings.SplineToLockMovementTo.Outer.Name + " but " + Player.Name + " is already locked to: " + SplineLockComp.Constrainer.SplineToLockMovementTo.Outer.Name);
		return;
	}

	Player.RootOffsetComponent.FreezeAndResetWithSpeed(LocationLerpSpeed, RotationLerpSpeed);

    Player.AddCapability(UMovementDirectionSplineInputCapability::StaticClass());
	// We assume the player already has the splinelock capability on them.

	SplineLockComp.LockOwnerToSpline(Settings);	
}

UFUNCTION(Category = "Movement|SplineLock")
void StopSplineLockMovement(AHazePlayerCharacter Player)
{
	auto SplineLockComp = USplineLockComponent::Get(Player);
	if (!devEnsure(SplineLockComp != nullptr, "Spline locks have not been active on: " + Player.Name))
		return;
	
	SplineLockComp.StopLocking();
}

UFUNCTION(Category = "Movement|SplineLock")
void StartLockPlayersToSplineAndMinDistanceFromEachOther(FConstraintSettings Settings, float PlayerMaxDistanceDif = 2600.f)
{
	for (AHazePlayerCharacter Player : Game::GetPlayers())
	{
		auto SplineLockComp = USplineLockComponent::GetOrCreate(Player);
		if (SplineLockComp.ActiveLockType != ESplineLockType::None)
		{
			devEnsure(false, "Trying to lock " + Player.Name + " to " + Settings.SplineToLockMovementTo.Outer.Name + " but " + Player.Name + " is already locked to: " + SplineLockComp.Constrainer.SplineToLockMovementTo.Outer.Name);
			return;
		}

		Player.AddCapability(UMovementDirectionSplineInputCapability::StaticClass());
		Player.AddCapability(ULockCharacterToSplineAndDistanceCapability::StaticClass());

		SplineLockComp.PlayerMaxSplineDistanceDif = PlayerMaxDistanceDif;
		SplineLockComp.LockOwnerToSpline(Settings, ESplineLockType::Distance);
	}
}

UFUNCTION(Category = "Movement|SplineLock")
void StopLockPlayersToSplineAndMinDistanceFromEachOther()
{
	for (AHazePlayerCharacter Player : Game::GetPlayers())
	{
		auto SplineLockComp = USplineLockComponent::Get(Player);
		if (!devEnsure(SplineLockComp.ActiveLockType == ESplineLockType::Distance, "Ending a distance spline lock while not in a distance spline lock mode"))
			continue;
		SplineLockComp.StopLocking();
	}
}
