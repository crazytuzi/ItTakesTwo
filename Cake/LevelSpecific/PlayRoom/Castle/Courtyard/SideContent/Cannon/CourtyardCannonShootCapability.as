import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Rice.Math.MathStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureCannonFly;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetActor;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
import Peanuts.Foghorn.FoghornStatics;

class UCourtyardCannonShootCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"CannonShoot");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 5;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCannonToShootMarblePlayerComponent CannonComponent;

	UPROPERTY()
	UForceFeedbackEffect CannonShootFeedback;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		CannonComponent = UCannonToShootMarblePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const override
	{
		if(!MoveComp.CanCalculateMovement())
			return false;
		else
			return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		
		if (CannonComponent.CannonActor.InteractingPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!CannonComponent.CannonActor.bPlayerReadyToBeShot)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;


		return EHazeNetworkActivation::ActivateUsingCrumb;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}		

		if (ActiveDuration < 0.5f)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (MoveComp.ForwardHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Effects and audio
		UHazeAkComponent::HazePostEventFireForget(CannonComponent.CannonActor.ShotFiredEvent, CannonComponent.CannonActor.ActorTransform);
		CannonComponent.CannonActor.NiagaraComponent.Activate(true);

		// Set that the cannon is firing with the correct player
		CannonComponent.CannonActor.InteractingPlayer = Player;
		CannonComponent.bIsBeeingShot = true;

		MoveComp.StartIgnoringActor(CannonComponent.CannonActor);

		// This will clear the cannon actor so we need to add it again
		Player.BlockCapabilities(n"Cannon", this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		FVector StartVel = CannonComponent.CannonActor.ShootDirection.ForwardVector * 5500.f;
		MoveComp.Velocity = StartVel;

		const auto& Data = CannonComponent.FlyOutOfCanonData;
		Player.AddLocomotionFeature(Data.Feature);

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 0.75f;
		//Player.ApplyCameraSettings(Data.CameraSettings, BlendSettings, this, EHazeCameraPriority::High);

		
		if (CannonShootFeedback != nullptr)
			Player.PlayForceFeedback(CannonShootFeedback, false, false, NAME_None, 1.f);

		CannonComponent.CannonActor.OnShootCannon.Broadcast(CannonComponent.CannonActor.InteractingPlayer);

		FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCannonFiredMay" : n"FoghornDBPlayroomCastleCannonFiredCody";
		PlayFoghornVOBankEvent(VOBank, EventName);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Cannon", this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		CannonComponent.CannonActor.OnPlayerHitSometing.Broadcast(Player);

		const auto& Data = CannonComponent.FlyOutOfCanonData;
		Player.RemoveLocomotionFeature(Data.Feature);
		Player.ClearCameraSettingsByInstigator(this, 1.f);

		// Need a temp variable since we will remove the capability from withing this function
		ACannonToShootMarbleActor CannonTempActor = CannonComponent.CannonActor;
		MoveComp.StopIgnoringActor(CannonComponent.CannonActor);

		CannonComponent.bIsBeeingShot = false;
		CannonComponent.CannonActor = nullptr;
		
		//KillPlayer(Player, Data.DeathEffect);
		CannonTempActor.RemoveCapabilityRequest(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CannonFly");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"CannonFly");
		
		CrumbComp.LeaveMovementCrumb();
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			// FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			// FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);

			Velocity -= Velocity * 0.2f * DeltaTime;
			//Velocity = RotateVectorTowardsAroundAxis(Velocity, MoveDirection, MoveComp.WorldUp, 45.f * DeltaTime);
			
			
			if (ActiveDuration < 0.4f)
				FrameMove.OverrideCollisionProfile(n"NoCollision");
			
			float GravityScale = 0.4f;

			//FrameMove.AddComponentToIgnore

			FrameMove.ApplyVelocity(MoveComp.Gravity * GravityScale * DeltaTime);
			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveComp.SetTargetFacingDirection(MoveComp.Velocity.GetSafeNormal());
		FrameMove.ApplyTargetRotationDelta();
	}
}