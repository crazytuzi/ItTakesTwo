import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBombCoreHitbox;

class UFlyingBombHeldCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombHeld");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;

	AFlyingBomb Bomb;
	UHazeMovementComponent MoveComp;
	AHazePlayerCharacter HoldingPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
		MoveComp = Bomb.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Bomb.HeldByBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Bomb.HeldByBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Bomb.CurrentState != EFlyingBombState::HeldByBird)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!Bomb.HeldByBird.bIsFlying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Bomb.HeldByBird.ActivePlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Time::GetGameTimeSince(Bomb.HeldSinceGameTime) > Bomb.MaxHeldTime && Bomb.MaxHeldTime > 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (IsActioning(n"DropBomb"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Player", Bomb.HeldByBird.ActivePlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HoldingPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"Player"));
		Bomb.SetControlSide(HoldingPlayer);
		Bomb.LocalWantHeldByBird = nullptr;
		Bomb.LastHeldPlayer = HoldingPlayer;

		Bomb.HeldSinceGameTime = Time::GameTimeSeconds;
		Bomb.State = EFlyingBombState::HeldByBird;
		Bomb.BlockCapabilities(n"FlyingBombAI", this);

		Bomb.RootComponent.AttachToComponent(Bomb.HeldByBird.HeldBombRoot);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& DeactivationParams)
	{
		const bool bExplode = (Bomb.HeldByBird != nullptr) && !IsActioning(n"DropBomb");
		if (bExplode)
		{
			DeactivationParams.AddActionState(n"Explode");
		}
	}

	UFUNCTION()
	private void ClearPointOfInterest()
	{
		if (!IsActive())
			HoldingPlayer.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Bomb.RootComponent.DetachFromParent(bMaintainWorldPosition = true);
		
		if(IsActioning(n"Explode"))
		{
			if(HoldingPlayer == Game::GetMay())
				PlayFoghornVOBankEvent(Bomb.VOBank, n"FoghornDBClockworkOutsideDropBombMay");
			else
				PlayFoghornVOBankEvent(Bomb.VOBank, n"FoghornDBClockworkOutsideDropBombCody");
		}

		if (DeactivationParams.GetActionState(n"Explode"))
		{
			Owner.SetCapabilityActionState(n"Explode", EHazeActionState::Active);
			Owner.SetCapabilityAttributeObject(n"HitPlayer", HoldingPlayer);

			HoldingPlayer.ClearPointOfInterestByInstigator(this);
		}
		else
		{
			Owner.SetCapabilityActionState(n"Dropped", EHazeActionState::Active);

			FVector TargetLocation;
			if (Bomb.HeldByBird != nullptr && !Bomb.HeldByBird.AutoAimPoint.IsNearlyZero())
			{
				TargetLocation = Bomb.HeldByBird.AutoAimPoint;
				Owner.SetCapabilityAttributeVector(n"LaunchTargetPoint", TargetLocation);
			}
			else
			{
				TargetLocation = HoldingPlayer.ViewLocation + (HoldingPlayer.ViewRotation.ForwardVector * 10000.f);
				Owner.SetCapabilityAttributeVector(n"LaunchTargetPoint", FVector::ZeroVector);
			}

			FVector LaunchDirection = (TargetLocation - Bomb.ActorLocation).GetSafeNormal();
			Owner.SetCapabilityAttributeVector(n"LaunchDirection", LaunchDirection);

			System::SetTimer(this, n"ClearPointOfInterest", 2.5f, false);
		}

		ConsumeAction(n"DropBomb");

		if (Bomb.HeldByBird != nullptr)
			Bomb.HeldByBird.bIsHoldingBomb = false;
		Bomb.HeldByBird = nullptr;
		auto BombTrackerComp = UBirdFlyingBombTrackerComponent::Get(HoldingPlayer);
		if (BombTrackerComp != nullptr)
			BombTrackerComp.HeldBomb = nullptr;
		Bomb.UnblockCapabilities(n"FlyingBombAI", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Bomb.VisualRoot.SetRelativeRotation(FMath::QInterpConstantTo(Bomb.VisualRoot.RelativeRotation.Quaternion(), FQuat(), DeltaTime, PI));
	}
};