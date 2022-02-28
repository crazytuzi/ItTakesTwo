import Cake.LevelSpecific.SnowGlobe.SnowAngel.PlayerSnowAngelComponent;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelArea;

class USnowAngelActionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SnowAngelAction");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerSnowAngelComponent PlayerSnowAngelComponent;

 	float CurrentAngelCycleValue;
	
	bool bIsMovingUp;
	bool bIsMovingDown;

	float SetPlayerAngelPositionTimer = 1.2f;

	float ArmMovementSpeed = 1.5f;
	FHazeAcceleratedFloat AcceleratedArmSpeed;

	ADecalActor DecalActor;

	AActor SpawnedActor;

	ASnowAngelArea SnowAngelArea;

	UHazeCrumbComponent CrumbComp;

	bool bCanDeactivate;
	bool bCancelWasPressed;
	bool bSnowAngelWasStarted;

	float DeactivateTimer = 0.68f;
	float AnimationEnterTimer = 0.62f;

	float NetworkRate = 0.25f;
	float NetworkNewTime;

	float FinalRightStickValue;

	bool bHaveMadeAction;
	bool bInputBlocked;

	FHazeAcceleratedFloat AudioValue;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	
		PlayerSnowAngelComponent = UPlayerSnowAngelComponent::Get(Player);
		PlayerSnowAngelComponent.bCanExit = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlayerSnowAngelComponent.bIsActive)
		 	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerSnowAngelComponent.bHasActivated)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		AcceleratedArmSpeed.SnapTo(0.f);

		if (Player.IsCody())
			Player.AddLocomotionFeature(PlayerSnowAngelComponent.SnowAngelFeatureCody);
		else
			Player.AddLocomotionFeature(PlayerSnowAngelComponent.SnowAngelFeatureMay);

		bCancelWasPressed = false;
		bCanDeactivate = false;

		SnowAngelArea = Cast<ASnowAngelArea>(GetAttributeObject(n"SnowAngelArea"));

		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.ApplyCameraSettings(PlayerSnowAngelComponent.CamSettings, PlayerSnowAngelComponent.CameraBlendSettingsSettings, this);

		System::SetTimer(this, n"SpawnDecal", AnimationEnterTimer, false);

		PlayerSnowAngelComponent.ShowCancelAngelPrompt(Player);

		if (!bHaveMadeAction)
			PlayerSnowAngelComponent.ShowAngelActionPrompt(Player);

		AudioValue.SnapTo(0.f);

		PlayerSnowAngelComponent.PlaySnowAngelVO(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		
		if (!Player.IsAnyCapabilityActive(CapabilityTags::Input) && bInputBlocked)
			Player.UnblockCapabilities(CapabilityTags::Input, this);

		Player.ClearCameraSettingsByInstigator(this);

		if (Player.IsCody())
			Player.RemoveLocomotionFeature(PlayerSnowAngelComponent.SnowAngelFeatureCody);
		else
			Player.RemoveLocomotionFeature(PlayerSnowAngelComponent.SnowAngelFeatureMay);	

		PlayerSnowAngelComponent.ResetCycleIterationValue();
		bIsMovingDown = false;
		bIsMovingUp = false;
		bSnowAngelWasStarted = false;

		SnowAngelArea.CheckDecalMaxAmount();

		PlayerSnowAngelComponent.ShowActivateAngelPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData LocoMotionRequestData;
		LocoMotionRequestData.AnimationTag = n"SnowAngel";
		Player.RequestLocomotion(LocoMotionRequestData);
		
		if (HasControl())
		{
			FinalRightStickValue = GetAttributeVector2D(AttributeVectorNames::MovementRaw).X;

			NetworkNewTime -= DeltaTime;

			if (NetworkNewTime <= 0.f)
			{
				NetworkNewTime = NetworkRate;
				StickValueControl(FinalRightStickValue);
			}
		}
		
		AcceleratedArmSpeed.AccelerateTo(FinalRightStickValue, 0.2f, DeltaTime);

		if (FMath::Abs(AcceleratedArmSpeed.Value) == 1.f && FMath::Sign(AcceleratedArmSpeed.Velocity) == FMath::Sign(AcceleratedArmSpeed.Value)) 
			AcceleratedArmSpeed.SnapTo(AcceleratedArmSpeed.Value, 0.f);

		if (FinalRightStickValue > 0)
		{
			PlayerSnowAngelComponent.RightAxisValue = FMath::Clamp(PlayerSnowAngelComponent.RightAxisValue + AcceleratedArmSpeed.Value * ArmMovementSpeed * DeltaTime, 0.f, 1.f);				
			
			if (bIsMovingDown)
			{
				PlayerSnowAngelComponent.SnowAngelCycleIteration++;
				bIsMovingDown = false;
			}

			bIsMovingUp = true;
			bSnowAngelWasStarted = true;

			if (!bHaveMadeAction)
			{
				PlayerSnowAngelComponent.HideAngelPrompt(Player);
				bHaveMadeAction =true;
			}
		}
		else if (FinalRightStickValue < 0 && bSnowAngelWasStarted)
		{
			PlayerSnowAngelComponent.RightAxisValue = FMath::Clamp(PlayerSnowAngelComponent.RightAxisValue + AcceleratedArmSpeed.Value * ArmMovementSpeed * DeltaTime, 0.f, 1.f);

			if (bIsMovingUp)
			{
				PlayerSnowAngelComponent.SnowAngelCycleIteration++;
				bIsMovingUp = false;
			}

			bIsMovingDown = true;

			if (!bHaveMadeAction)
			{
				PlayerSnowAngelComponent.HideAngelPrompt(Player);
				bHaveMadeAction =true;
			}
		}

		float Target;

		if (PlayerSnowAngelComponent.RightAxisValue == 1.f || PlayerSnowAngelComponent.RightAxisValue == 0.f)
			Target = 0.f;
		else if (FinalRightStickValue == 0.f)
			Target = 0.f;
		else
			Target = 1.f;

		AudioValue.AccelerateTo(Target, 0.15f, DeltaTime);

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_SnowGlobe_Interactions_SnowAngels_PlayerInput", AudioValue.Value);

		if (WasActionStarted(ActionNames::Cancel) && !bCancelWasPressed)
		{
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

			PlayerSnowAngelComponent.HideCancelPrompt(Player);	

			if (HasControl())
				CancelCheck();
		}
	}

	UFUNCTION(NetFunction)
	void StickValueControl(float Input)
	{
		FinalRightStickValue = Input;
	}

	UFUNCTION(NetFunction)
	void CancelCheck()
	{
		System::SetTimer(this, n"SetCanDeactivateTrue", DeactivateTimer, false);
		PlayerSnowAngelComponent.bCanExit = true;
		Player.BlockCapabilities(CapabilityTags::Input, this);
		bInputBlocked = true;
		bCancelWasPressed = true;
	}

	UFUNCTION()
	void SpawnDecal()
	{
		if (SnowAngelArea == nullptr)
			return;
			
		FRotator SpawnRotationOffset = FRotator(0,-91.f,0);
		FVector SpawnPositionOffsetCody = Player.GetActorForwardVector() * 14.f;
		FVector SpawnPositionOffsetMay = Player.GetActorForwardVector() * 6.f;

		if (Player.IsCody())
			DecalActor = Cast<ADecalActor>(SpawnActor(PlayerSnowAngelComponent.DecalActorType[Player], Owner.ActorLocation + SpawnPositionOffsetCody, Owner.ActorRotation + SpawnRotationOffset, NAME_None)); 
		else
			DecalActor = Cast<ADecalActor>(SpawnActor(PlayerSnowAngelComponent.DecalActorType[Player], Owner.ActorLocation + SpawnPositionOffsetMay, Owner.ActorRotation + SpawnRotationOffset, NAME_None)); 

		SnowAngelArea.DecalCompArray.Add(DecalActor);

		PlayerSnowAngelComponent.MaterialInstance = DecalActor.Decal.CreateDynamicMaterialInstance();
	}

	UFUNCTION()
	void SetCanDeactivateTrue()
	{
		PlayerSnowAngelComponent.bIsActive = false;
		PlayerSnowAngelComponent.bHasActivated = false;
	}
}