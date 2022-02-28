import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingHazeWidget;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;

class UCurlingPlayerTargetingCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"CurlingPlayerTargetingCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 110;

	AHazePlayerCharacter Player;
	ACurlingStone TargetStone;
	UIceSkatingComponent SkateComp;
	UCurlingPlayerComp PlayerComp;

	FCurlingSkateSettings CurlingSettings;
	UCurlingHazeWidget Widget;

	bool bIsPoweringDownwards;
	float PowerPercentage = 0.f;
	float PowerFrequency = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
		SkateComp = UIceSkatingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Targeting)
	        return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStopped(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);

		if (TargetStone == nullptr)
			return;

		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(IceSkatingTags::IceSkating, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		Player.TriggerMovementTransition(this);
		
		PlayerComp.CurlingPower = 0.f;
		PowerPercentage = 0.f;
	
		TargetStone.bHasPlayed = true;

		Widget = Cast<UCurlingHazeWidget>(Player.AddWidgetToHUDSlot(n"LevelAbility", PlayerComp.CurlingWidget));
		
		Widget.AttachWidgetToComponent(Player.RootComponent);
		Widget.BP_SetProgress(PowerPercentage);

		PlayerComp.bCanCancel = false;

		PlayerComp.HideCurlTutorialPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		OutParams.AddValue(n"CurlingPower", PlayerComp.CurlingPower);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		TargetStone.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		TargetStone.TriggerMovementTransition(this);

		if (DeactivationParams.GetActionState(n"bShouldFall"))
			PlayerComp.PlayerCurlState = EPlayerCurlState::Default;
		else
			PlayerComp.PlayerCurlState = EPlayerCurlState::Shooting;

		Player.RemoveWidget(Widget);

		Widget = nullptr;

		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(IceSkatingTags::IceSkating, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		PlayerComp.CurlingPower = DeactivationParams.GetValue(n"CurlingPower");	
		PlayerComp.bCanCancel = true;
	}

	//REMOVED DUE TO BEING ABLE TO ROTATE INTO WALLS AND OUTSIDE THE LINE 
	// void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	// {	
	// 	if (HasControl())
	// 	{
	// 		FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);
	// 		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);

	// 		float InputStrength = FMath::Clamp(CameraInput.X + MoveInput.Y, -1.f, 1.f);
	// 		float RotationRate = CurlingSettings.RotationRate * InputStrength;
	// 		PlayerComp.AcceleratedTurnRate.AccelerateTo(RotationRate, CurlingSettings.RotationRateAccelerationDuration, DeltaTime);

	// 		FQuat RotationQuat = FQuat(MoveComp.WorldUp, PlayerComp.AcceleratedTurnRate.Value * DEG_TO_RAD * DeltaTime);
	// 		FVector TargetDirection = Owner.ActorForwardVector;
	// 		TargetDirection = RotationQuat * TargetDirection;

	// 		MoveComp.SetTargetFacingDirection(TargetDirection);
	// 	}
	// 	else
	// 	{
	// 		FHazeActorReplicationFinalized ConsumedParams;
	// 		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

	// 		FHazeReplicatedFrameMovementSettings FrameSettings;
	// 		FrameSettings.bUseReplicatedRotation = false;

	// 		FrameMove.ApplyConsumedCrumbData(ConsumedParams, FrameSettings);

	// 		FRotator CrumbRotation = ConsumedParams.Rotation;
	// 		PlayerComp.AcceleratedRemoteRotation.AccelerateTo(CrumbRotation, CurlingSettings.RemoteAcceleratedRotationDuration, DeltaTime);
	// 		MoveComp.SetTargetFacingRotation(PlayerComp.AcceleratedRemoteRotation.Value);
	// 	}

	// 	FrameMove.ApplyTargetRotationDelta(); 		
	// }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		// if (MoveComp.CanCalculateMovement())
		// {
		// 	FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CurlingMovement");
		// 	CalculateFrameMove(FrameMove, DeltaTime);
		// 	MoveCharacter(FrameMove, n"CurlingMovement");
			
		// 	CrumbComp.LeaveMovementCrumb();
		// }
			
		if (!bIsPoweringDownwards)
		{
			PowerPercentage = PowerPercentage + (PowerFrequency * DeltaTime);
			if (PowerPercentage >= 1.f)
				bIsPoweringDownwards = true;

			PowerPercentage = FMath::Clamp(PowerPercentage, 0.f, 1.f);
		}
		else
		{
			PowerPercentage = PowerPercentage - (PowerFrequency * DeltaTime);
			if (PowerPercentage <= 0.f)
				bIsPoweringDownwards = false;

			PowerPercentage = FMath::Clamp(PowerPercentage, 0.f, 1.f);
		}
		float PowerPercentageCurved = PlayerComp.PowerCurve.GetFloatValue(PowerPercentage);

		PlayerComp.CurlingPower = PowerPercentageCurved * PlayerComp.MaxCurlingPower;			
		PlayerComp.PlayerShootForwardVector = Player.ActorForwardVector;

		PlayerComp.TargetingBlendSpaceValue = PowerPercentage;
		if (Widget != nullptr)
			Widget.BP_SetProgress(PowerPercentageCurved);
	
	}
}