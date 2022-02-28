import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.ButtonMashStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

class SpiderDefenseCapability : UHazeCapability
{
    UPROPERTY()
    UAnimSequence DefenseAnim;

	UPROPERTY()
	UAnimSequence DeathAnim;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSetting;

	default CapabilityTags.Add(n"ZombieNail");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;

	UButtonMashProgressHandle ButtonMashHandle;

	float ButtonMashProgress = 0.99f;
	float ButtonMashStrength = 1.f;
	float ButtonMashDecreaseRate = 0.5f;
	float WeightedMashRate = 0.f;
	float ButtonMashIncreaseRate = 0.f;
	float ButtonMashIncreaseRateMultiplier = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeNumber(n"SpiderDefense") == 1)
        	return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ButtonMashProgress <= 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Player.BlockCapabilities(n"Movement", this);
        Player.BlockCapabilities(n"Weapon", this);
        Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), DefenseAnim, true);
        ButtonMashHandle = StartButtonMashProgressAttachToActor(Player, Player, FVector(0,0,100));
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 2.0f;
		Player.ApplyCameraSettings(CameraSetting, BlendSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ButtonMashProgress = 0.99f;
		ButtonMashStrength = 1.f;
		ButtonMashDecreaseRate = 0.5f;
		WeightedMashRate = 0.f;
		ButtonMashIncreaseRate = 0.f;
		ButtonMashIncreaseRateMultiplier = 0.f;
		Player.SetCapabilityAttributeNumber(n"SpiderDefense", 0);
		StopButtonMash(ButtonMashHandle);
		FHazeAnimationDelegate BlendingOutEvent;
		// BlendingOutEvent.BindUFunction(this, n"KillFunction");
		// Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendingOutEvent, DeathAnim, false);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Weapon", this);
		KillPlayer(Player, DeathEffect);
		PlaySpiderAnim();
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintEvent)
	void PlaySpiderAnim()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
    
    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
    
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateButtonMashProgress(DeltaTime);
	}

	void UpdateButtonMashProgress(float DeltaTime)
	{
		ButtonMashStrength = ButtonMashStrength - (0.1f * DeltaTime);
		WeightedMashRate = ButtonMashHandle.MashRateControlSide * ButtonMashStrength;
		ButtonMashIncreaseRateMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0,1), FVector2D(5,0.5), ButtonMashProgress);
		ButtonMashIncreaseRate = FMath::GetMappedRangeValueClamped(FVector2D(0, 5), FVector2D(0, ButtonMashDecreaseRate * ButtonMashIncreaseRateMultiplier), WeightedMashRate);
		ButtonMashProgress = (ButtonMashProgress - (ButtonMashDecreaseRate * DeltaTime) + (ButtonMashIncreaseRate * DeltaTime));
		ButtonMashHandle.Progress = ButtonMashProgress;
	}

	// UFUNCTION()
	// void KillFunction()
	// {
	//
	// }
}