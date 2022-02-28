import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePlayerLeverComponent;
import Cake.Weapons.Sap.SapWeaponNames;
import Vino.Movement.MovementSystemTags;
class USelfiePlayerLeverRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfiePlayerLeverRotateCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCameraUserComponent UserComp;
	USelfiePlayerLeverComponent PlayerComp;

	FHazeAcceleratedRotator AccelRot;
	float NetAccelTarget;

	float NetRate = 0.4f;
	float NetTime;
	FRotator NetDesiredRot;
	FRotator DesiredRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USelfiePlayerLeverComponent::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCameraSyncronization(this);
		AccelRot.SnapTo(Player.ViewRotation);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(PlayerComp.CamSettings, Blend, this);

		PlayerComp.ShowPlayerCancel(Player);

		PlayerComp.ShowLeftTurnPrompt(Player);
		PlayerComp.ShowRightTurnPrompt(Player);

		NetTime = NetRate;

		FVector Direction = (PlayerComp.Stage.ActorLocation - Player.ActorLocation);
		Direction.Normalize();
	 	DesiredRot = FRotator::MakeFromX(Direction);

		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Player.BlockCapabilities(MovementSystemTags::AirMovement, this);
		Player.BlockCapabilities(MovementSystemTags::FloorJump, this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(MovementSystemTags::AirDash, this);
		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::AirJump, this);
		Player.BlockCapabilities(SapWeaponTags::Aim, this);
		Player.BlockCapabilities(n"MatchWeaponAim", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCameraSyncronization(this);
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
		PlayerComp.HideAllTutorialPrompts(Player);

		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Player.UnblockCapabilities(MovementSystemTags::AirMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::FloorJump, this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(MovementSystemTags::AirDash, this);
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::AirJump, this);
		Player.UnblockCapabilities(SapWeaponTags::Aim, this);
		Player.UnblockCapabilities(n"MatchWeaponAim", this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (PlayerComp.Stage.bCanRotate)
			return;

		if (HasControl())
		{
			if (WasActionStarted(ActionNames::SecondaryLevelAbility))
			{
				PlayerComp.Stage.NetActivateStageRotation(EStageDirection::Right);
				NetRotateStage(EStageDirection::Right);
			}

			if (WasActionStarted(ActionNames::PrimaryLevelAbility))
			{
				PlayerComp.Stage.NetActivateStageRotation(EStageDirection::Left);
				NetRotateStage(EStageDirection::Left);
			}
		}

		AccelRot.AccelerateTo(DesiredRot, 1.2f, DeltaTime);
		UserComp.DesiredRotation = AccelRot.Value;
	}

	UFUNCTION(NetFunction)
	void NetRotateStage(EStageDirection StageDirection)
	{
		if (!HasControl())
			PlayerComp.Stage.NetActivateStageRotation(StageDirection);
	}
}