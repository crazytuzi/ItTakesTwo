import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
class USnailRaceSnailPlayerControlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnailRaceCapability");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASnailRaceSnailActor Snail;
	float HoldTime = 0;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"RidingSnail") != nullptr)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}

		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"StopRidingSnail"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UObject ConvertedSnail;
		ConsumeAttribute(n"RidingSnail", ConvertedSnail);
		ActivationParams.AddObject(n"RidingSnail", ConvertedSnail);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Snail = Cast<ASnailRaceSnailActor>(ActivationParams.GetObject(n"RidingSnail"));

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::LevelSpecific, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.TriggerMovementTransition(this);
		Player.AttachToComponent(Snail.Body, n"SnailRaceAttach", AttachmentRule = EAttachmentRule::SnapToTarget);
		Player.DisableMovementComponent(this);
		Player.BlockMovementSyncronization(this);
		Snail.EnableMovementComponent(Snail);
		
		if (Player.IsCody())
		{
			Player.AddLocomotionFeature(CodyFeature);
		}
		else
		{
			Player.AddLocomotionFeature(MayFeature);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Snail.DisableMovementComponent(Snail);
		Snail = nullptr;
		ConsumeAction(n"StopRidingSnail");

		Player.UnblockCapabilities(CapabilityTags::LevelSpecific, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.TriggerMovementTransition(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		
		Player.EnableMovementComponent(this);
		Player.UnblockMovementSyncronization(this);

		if (Player.IsCody())
		{
			Player.RemoveLocomotionFeature(CodyFeature);
		}
		else
		{
			Player.RemoveLocomotionFeature(MayFeature);
		}

		HoldTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (Snail.bBlockSnailValue) //SQUISHVALUE NOT SYNCED OVER NETWORK!
			{
				Snail.SquishValue = 1;
			}
			else if (IsActioning(ActionNames::MovementDash) && Snail.SnailBoost == 0 && !Snail.bBlockSnailValue)
			{
				HoldTime += DeltaTime;
				HoldTime = FMath::Clamp(HoldTime, 0.f, 0.5f);
				float SquishValue = 1 - HoldTime * 2.f;
				SquishValue = FMath::Clamp(SquishValue, 0.2f, 1.f);
				Snail.SquishValue = SquishValue;
			}
			else
			{
				if (HoldTime > 0.2f)
				{
					Snail.SnailBoost = (HoldTime * HoldTime) * 1.5f;
				}
				Snail.SnailBoost -= DeltaTime;
				Snail.SnailBoost = FMath::Clamp(Snail.SnailBoost, 0.f, 10.f);
				HoldTime = 0;
				Snail.SquishValue = 1.f;
			}
		}

		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		Snail.SetDesiredMoveDir(MoveDirection);

		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"SnailRace";
		Player.RequestLocomotion(Data);
		
	}
}