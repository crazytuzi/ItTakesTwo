import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Vino.Movement.Components.MovementComponent;

UCLASS(Deprecated)
class UMusicalFlyingActivateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(n"MusicalFlyingActivate");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;
	UMusicalFlyingComponent FlyingComp;
	UHazeMovementComponent MoveComp;

	UMusicalFlyingSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UMusicalFlyingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(FlyingComp.ExitVolumeBehavior == EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		
		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.bFly)
			return EHazeNetworkActivation::DontActivate;

		if(!FlyingComp.bFlyingPressed)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlyingComp.bStartedOnGround = MoveComp.IsGrounded();

		FlyingComp.SetFlyingState(EMusicalFlyingState::Flying);
		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

		if(CymbalComp != nullptr)
		{
			CymbalComp.ApplyFlyingSettings(this);
			CymbalComp.SetCanAttachToObjects(false);
		}

		if(FlyingComp.bWasHovering)
		{
			FlyingComp.FlyingStartupTime = Settings.StartDelayFromHover;
			FlyingComp.StartupMovementDirection = FVector::ZeroVector;
			FlyingComp.StartupFacingDirection = Player.ViewRotation.ForwardVector;
			
		}
		else
		{
			// Flying starts from ground in this case
			FlyingComp.FlyingStartupTime = Settings.StartDelay;
			FlyingComp.StartupMovementDirection = FVector::UpVector;
			FlyingComp.StartupFacingDirection = Player.ActorForwardVector;
			FlyingComp.PreventCancelTimeElapsed = Settings.PreventCancelTime;
			if(CymbalComp != nullptr)
			{
				CymbalComp.AttachCymbalToSocket(n"RightAttach");
				CymbalComp.BlockCatchAnimation();
				CymbalComp.BackSocket = n"RightAttach";
			}
		}

		USingingComponent SingingComp = USingingComponent::Get(Owner);

		if(SingingComp != nullptr)
		{
			SingingComp.ApplyFlyingSettings(this);
		}

		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"WeaponAim", this);
		Player.BlockCapabilities(n"CymbalShield", this);
		Player.BlockCapabilities(n"SongOfLife", this);
		Player.BlockCapabilities(n"PowerfulSongCharge", this);
		Player.ApplyCameraSettings(FlyingComp.FlyingCamSettings, FHazeCameraBlendSettings(2.0f), this, EHazeCameraPriority::High);

		FlyingComp.OnEnterFlying();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(FlyingComp.ExitVolumeBehavior == EMusicalFlyingExitVolumeBehavior::HalfLoop)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(FlyingComp.bDoLoop)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (FlyingComp.CurrentState != EMusicalFlyingState::Flying)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!FlyingComp.bFlyingValid)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!FlyingComp.bFly)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ConsumeAction(ActionNames::MovementGroundPound);

		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Player.UnblockCapabilities(n"WeaponAim", this);
		Player.UnblockCapabilities(n"CymbalShield", this);
		Player.UnblockCapabilities(n"SongOfLife", this);
		Player.UnblockCapabilities(n"PowerfulSongCharge", this);

		// TODO: Move these somewhere else, such as it's own capability.

		UCymbalComponent CymbalComp = UCymbalComponent::Get(Owner);

		if(CymbalComp != nullptr)
		{
			CymbalComp.ClearFlyingSettings(this);
			CymbalComp.SetCanAttachToObjects(true);
		}

		USingingComponent SingingComp = USingingComponent::Get(Owner);

		if(SingingComp != nullptr)
		{
			SingingComp.ClearFlyingSettings(this);
		}

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FlyingComp.FlyingStartupTime -= DeltaTime;
	}
}
