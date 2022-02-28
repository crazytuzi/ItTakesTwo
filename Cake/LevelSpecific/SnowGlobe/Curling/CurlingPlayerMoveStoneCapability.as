import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCustomVelocityCalculator;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingGameManager;

class UCurlingPlayerMoveStoneCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"CurlingPlayerMoveStoneCapability");

	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ACurlingStone TargetStone;
	UIceSkatingComponent SkateComp;
	UCurlingPlayerComp PlayerComp;
	ACurlingGameManager GameManager;

	FCurlingSkateSettings CurlingSettings;

	bool bPlayingGlide;

	FHazeAcceleratedFloat AccelStoneAudio;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		SkateComp = UIceSkatingComponent::Get(Player);
		GameManager = GetCurlingGameManager();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::MoveStone)
	        return EHazeNetworkActivation::DontActivate;

	    return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && PlayerComp.bCanCancel)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ShouldTargetFall())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (IsActioning(ActionNames::PrimaryLevelAbility) && PlayerComp.bCanTargetAndFire)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::MoveStone)
	        return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationSyncParams)
	{
		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);

		if (TargetStone == nullptr)
			return;

		ActivationSyncParams.AddVector(n"StoneStartLoc", Player.ActorTransform.InverseTransformPosition(TargetStone.ActorLocation));
		ActivationSyncParams.AddObject(n"TargetObj", TargetStone);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.TargetStone = ActivationParams.GetObject(n"TargetObj");
		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);

		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		PlayerComp.ShowCurlCancelPrompt(Player);
		TargetStone.DisableAllOtherPucks();

		FVector Direction = TargetStone.ActorLocation - Player.ActorLocation;

		PlayerComp.AcceleratedTurnRate.SnapTo(0.f);
		PlayerComp.AcceleratedRemoteRotation.SnapTo(Player.ActorRotation);

		StoneAttachState(true, ActivationParams.GetVector(n"StoneStartLoc"));

		AccelStoneAudio.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)	
	{
		if (WasActionStarted(ActionNames::Cancel) && PlayerComp.bCanCancel
			|| ShouldTargetFall())
		{
			OutParams.AddActionState(n"bCancelled");
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (DeactivationParams.GetActionState(n"bCancelled"))
		{
			PlayerComp.PlayerCurlState = EPlayerCurlState::Default;
			StoneAttachState(false);
		}
		else if (PlayerComp.PlayerCurlState == EPlayerCurlState::Default)
			StoneAttachState(false);
		else
			PlayerComp.PlayerCurlState = EPlayerCurlState::Targeting;
		
		TargetStone.EnableAllOtherPucks();

		TargetStone.bIsControlledByPlayer = false;

		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);
 
		PlayerComp.HideCurlTutorialPrompt(Player);
	}

	UFUNCTION()
	void StoneAttachState(bool bIsAttached = false, FVector InputLoc = FVector(0.f))
	{
		if (TargetStone == nullptr)
			return;

		if (bIsAttached)
		{
			TargetStone.AttachToActor(Player, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			TargetStone.TriggerMovementTransition(this);
		}
		else
		{
			TargetStone.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			TargetStone.TriggerMovementTransition(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LastYaw = Player.ActorRotation.Yaw; 

		if (GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).Size() != 0.f)
			PlayerComp.bIsUsingLeftStick = true;
		else 
			PlayerComp.bIsUsingLeftStick = false;

		if (!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"CurlingMovement");
		FrameMove.OverrideStepDownHeight(120.f);

		FVector Input = SkateComp.GetScaledPlayerInput();

		if (HasControl())
		{
			FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);

			float RotationRate = CurlingSettings.RotationRate * CameraInput.X;
			PlayerComp.AcceleratedTurnRate.AccelerateTo(RotationRate, CurlingSettings.RotationRateAccelerationDuration, DeltaTime);

			// Calculate the slope multiplier, so we don't accelerate if we're trying to go up slopes
			
			// 	return;
			// We want to limit our acceleration going up slopes
			FVector SlopeInput = SkateComp.TransformVectorToGround(Input);
			float SlopeMultiplier = 0.f;
			float Slope = SlopeInput.DotProduct(FVector::UpVector);
			float MaxSlopeSin = FMath::Sin(CurlingSettings.MaxSlope * DEG_TO_RAD);

			SlopeMultiplier = 1.f - Math::Saturate(Slope / MaxSlopeSin);

			// Apply forces! - dividing to control speed
			FVector Velocity = SkateComp.TransformVectorToGround(MoveComp.Velocity / 1.025f);

			Velocity += SlopeInput * CurlingSettings.Acceleration * SlopeMultiplier * DeltaTime;
			Velocity -= Velocity * CurlingSettings.Friction * DeltaTime;

			FVector MoveDelta = Velocity * DeltaTime;

			FQuat RotationQuat = FQuat(MoveComp.WorldUp, PlayerComp.AcceleratedTurnRate.Value * DEG_TO_RAD * DeltaTime);
			FVector TargetDirection = Owner.ActorForwardVector;
			TargetDirection = RotationQuat * TargetDirection;
			
			MoveDelta = TargetStone.CollisionStrafeCheck(Player, MoveDelta, TargetDirection);
			
			if (PlayerComp.PlayerCurlState != EPlayerCurlState::Targeting)
				FrameMove.ApplyDelta(MoveDelta);
				
			FrameMove.FlagToMoveWithDownImpact();
			MoveComp.SetTargetFacingDirection(TargetDirection);
			FrameMove.ApplyTargetRotationDelta();

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);

			// CrumbData.Rotation = AccelRotate.Value;
			FHazeReplicatedFrameMovementSettings FrameSettings;
			FrameSettings.bUseReplicatedRotation = false;

			FrameMove.ApplyConsumedCrumbData(CrumbData, FrameSettings);

			FRotator CrumbRotation = CrumbData.Rotation;
			PlayerComp.AcceleratedRemoteRotation.AccelerateTo(CrumbRotation, CurlingSettings.RemoteAcceleratedRotationDuration, DeltaTime);
			MoveComp.SetTargetFacingRotation(PlayerComp.AcceleratedRemoteRotation.Value);

			FrameMove.ApplyTargetRotationDelta();
		}

		MoveCharacter(FrameMove, n"CurlingMovement");	

		float CurrentYaw = Player.ActorRotation.Yaw;

		float YawSpeed = FMath::Abs(CurrentYaw - LastYaw);
		
		YawSpeed *= 25.f;
		float PlayerVelocity = Player.MovementComponent.Velocity.Size() * 0.05f; 

		float TargetFinalStoneAudio = FMath::Clamp(PlayerVelocity + YawSpeed, 0.f, 45.f); 
		
		AccelStoneAudio.AccelerateTo(TargetFinalStoneAudio, 0.5f, DeltaTime);

		if (AccelStoneAudio.Value > 0.5f && !bPlayingGlide)
		{
			TargetStone.AudioStartGlideEvent();	
			bPlayingGlide = true;
		}
		else if (AccelStoneAudio.Value < 0.5f && bPlayingGlide)
		{
			TargetStone.AudioEndGlideEvent();	
			bPlayingGlide = false;		
		}
		
		TargetStone.AudioUpdateGlideRTPC(AccelStoneAudio.Value);
	}

	bool ShouldTargetFall() const
	{
		FVector PlayerDelta = Player.ActorLocation - GameManager.EdgeTransform.ActorLocation;
		FVector StoneDelta = TargetStone.ActorLocation - GameManager.EdgeTransform.ActorLocation;

		float PlayerDistanceFromLedge = GameManager.EdgeTransform.ActorForwardVector.DotProduct(PlayerDelta);
		float StoneDistanceFromLedge = GameManager.EdgeTransform.ActorForwardVector.DotProduct(StoneDelta);

		if (PlayerDistanceFromLedge > 20.0f || StoneDistanceFromLedge > 50.f)
			return true;

		return false;
	}
}
