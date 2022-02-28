import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarbleActor;
import Rice.Math.MathStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureCannonFly;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetActor;
import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonToShootMarblePlayerComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.GoldbergVOBank;


class UFlyOutOfCannonCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::MovementAction);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	UGoldbergVOBank VOBank;

	UPROPERTY()
	UForceFeedbackEffect LaunchForceFeedback;

	AHazePlayerCharacter Player;
	UCannonToShootMarblePlayerComponent CannonComponent;
	bool bShouldExit = false;
	bool bHasMissed = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		CannonComponent = UCannonToShootMarblePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!CannonComponent.bIsBeeingShot)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bShouldExit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// This will clear the cannon actor so we need to add it again
		Player.BlockCapabilities(n"Cannon", this);

		FVector StartVel = CannonComponent.CannonActor.ShootDirection.ForwardVector * CannonComponent.CannonActor.LaunchForce;
		MoveComp.Velocity = StartVel;

		const auto& Data = CannonComponent.FlyOutOfCanonData;
		Player.AddLocomotionFeature(Data.Feature);

		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 0.75f;
		CannonComponent.bIsBeeingShot = true;
		MoveComp.StartIgnoringActor(CannonComponent.CannonActor);
		Player.ApplyCameraSettings(Data.CameraSettings, BlendSettings, this, EHazeCameraPriority::High);

		bHasMissed = false;

		Player.PlayForceFeedback(LaunchForceFeedback, false, true, n"CannonLaunch");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Cannon", this);
		CannonComponent.CannonActor.OnPlayerHitSometing.Broadcast(Player);

		const auto& Data = CannonComponent.FlyOutOfCanonData;
		Player.RemoveLocomotionFeature(Data.Feature);
		Player.ClearCameraSettingsByInstigator(this, 1.f);

		// Need a temp variable since we will remove the capability from withing this function
		ACannonToShootMarbleActor CannonTempActor = CannonComponent.CannonActor;
		MoveComp.StopIgnoringActor(CannonComponent.CannonActor);

		CannonComponent.bHitBaloon = false;
		CannonComponent.bIsBeeingShot = false;
		CannonComponent.CannonActor = nullptr;
		bShouldExit = false;
		
		KillPlayer(Player);
		CannonTempActor.RemoveCapabilityRequest(Player);

		if(bHasMissed)
		{
			if(Player.GetOtherPlayer().IsCody())
			{
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomCircusCannonCodyMiss", Player.GetOtherPlayer());
				
			}
			else
			{
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomCircusCannonMayMiss", Player.GetOtherPlayer());
			}
			
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CannonFly");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"CannonFly");
		
		CrumbComp.LeaveMovementCrumb();	

		if(HasControl())
		{
			UpdateExitCoditions();
		}
	}	

	void UpdateExitCoditions()
	{	
		bool bSetHasMissed = false;

		if (CannonComponent.bHitBaloon)
		{
			bShouldExit = true;
		}
			
		else if (MoveComp.ForwardHit.bBlockingHit && (MoveComp.ForwardHit.Actor != CannonComponent.Owner))
		{
			bShouldExit = true;
			bSetHasMissed = true;
		}
			

		else if (MoveComp.IsGrounded())
		{
			bShouldExit = true;
			bSetHasMissed = true;
		}
			

		if(bShouldExit)
		{
			FHazeDelegateCrumbParams CrumbParams;

			if (bSetHasMissed)
			{
				CrumbParams.AddActionState(n"HasMissed");
			}
				
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbTriggerExit"), CrumbParams);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CrumbTriggerExit(const FHazeDelegateCrumbData& CrumbData)
	{
		if (CrumbData.GetActionState(n"HasMissed"))
		{
			bHasMissed = true;
		}
		bShouldExit = true;
	}

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);

			Velocity -= Velocity * 0.225f * DeltaTime;
			Velocity = RotateVectorTowardsAroundAxis(Velocity, MoveDirection, MoveComp.WorldUp, 45.f * DeltaTime);
			


			if (ActiveDuration < 0.5f)
			{
				FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
			}
			
			float GravityScale = 0.25f;

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