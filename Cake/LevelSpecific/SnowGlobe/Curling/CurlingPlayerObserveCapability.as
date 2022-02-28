import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingGameManager;
import Vino.Camera.Capabilities.CameraTags;

class UCurlingPlayerObserveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingShootCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UMagneticPlayerComponent MagnetComp;
	UCurlingPlayerComp PlayerComp;	
	
	ACurlingStone TargetStone;
	ACurlingGameManager GameManager;

	UCameraUserComponent UserComp;

	float TotalSpeed = 0.f;

	float FinalShotThreshold = 700.f;

	float CompleteShotThreshold = 60.f;

	bool bCanFinalShot;

	bool bShouldDeactivate;

	float TimeCheck;
	float MaxTimeCheck = 15.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MagnetComp = UMagneticPlayerComponent::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);

		GameManager = GetCurlingGameManager();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{				
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Observing)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Observing)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (FMath::IsNearlyZero(GetTotalSpeed(), CompleteShotThreshold))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (TargetStone != nullptr)
			if (TargetStone.bHaveFallen)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bShouldDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(IceSkatingTags::IceSkating, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		
		bShouldDeactivate = false;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.0f;

		GameManager.CurlingCameraManager[Player].FollowCam.ActivateCamera(Player, Blend, this);
		GameManager.CurlingCameraManager[Player].ChangeCameraState(ECurlingCamManagerState::Following);
		
		if (GetTotalSpeed() > FinalShotThreshold)
			bCanFinalShot = true;
		else
			bCanFinalShot = false;

		TargetStone = Cast<ACurlingStone>(PlayerComp.TargetStone);
		GameManager.CurlingCameraManager[Player].InPlayCurlingStone = TargetStone;

		TimeCheck = MaxTimeCheck;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(IceSkatingTags::IceSkating, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		GameManager.CurlingCameraManager[Player].FollowCam.DeactivateCamera(Player, 1.6f);

		PlayerComp.PlayerCurlState = EPlayerCurlState::Default;

		GameManager.CurlingCameraManager[Player].ChangeCameraState(ECurlingCamManagerState::Inactive);

		if (HasControl())	
		{
			GameManager.NetReturnPlayerDefaultStates(Player);
			System::SetTimer(this, n"DelayedCheckPlaysAndGameState", 1.4f, false);
		}

		TargetStone = nullptr;

		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Observing)
			PlayerComp.PlayerCurlState = EPlayerCurlState::Default;
	}

	UFUNCTION()
	void DelayedCheckPlaysAndGameState()
	{
		GameManager.NetUpdatePlaysAndCheckGameState(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentTotalSpeed = GetTotalSpeed();

		if (CurrentTotalSpeed > 0.f)
			if (CurrentTotalSpeed <= FinalShotThreshold && GameManager.CurlingCameraManager[Player].CamManagerState == ECurlingCamManagerState::Following && bCanFinalShot)
				GameManager.CurlingCameraManager[Player].ChangeCameraState(ECurlingCamManagerState::FinalShot);

		TimeCheck -= DeltaTime;

		if (TimeCheck <= 0.f)
			bShouldDeactivate = true;
	}

	float GetTotalSpeed() const
	{
		TArray<ACurlingStone> OwnersCurlingStones = Player.IsMay() ? GameManager.ActiveStonesArrayMay : GameManager.ActiveStonesArrayCody;
		
		float SpeedAdd = 0.f;
		
		for (ACurlingStone Stone : OwnersCurlingStones)
			SpeedAdd += Stone.MoveComp.Velocity.Size();

		return SpeedAdd;
	}
}