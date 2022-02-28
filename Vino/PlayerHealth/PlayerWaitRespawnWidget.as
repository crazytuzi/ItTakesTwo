import Vino.PlayerHealth.PlayerRespawnComponent;

class UPlayerWaitRespawnWidget : UHazeUserWidget
{
	UPROPERTY()
	float SuccessDisplayDuration = 0.3f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float RespawnProgress = 0.f;

	UPROPERTY()
	UWidget MainOverlay;

	UMaterialInstanceDynamic DynamicMaterial;
	UPlayerRespawnComponent RespawnComp;
	UPlayerHealthSettings HealthSettings;
	bool bStarted = false;

	private float DisplayedProgress = 0.f;
	private float DisplayedSuccess = 0.f;

	UFUNCTION()
	void InitMaterial(UMaterialInstanceDynamic Material)
	{
		DynamicMaterial = Material;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		RespawnComp = UPlayerRespawnComponent::Get(Player);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Pulse() {}

	UFUNCTION(BlueprintEvent)
	void BP_HiddenFromFinished() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		// Update bump dots
		if (RespawnComp.bWaitingForRespawn)
		{
			bStarted = true;

			RespawnProgress = RespawnComp.CurrentRespawnProgress;

			if (RespawnComp.bRespawnMashPulse)
				BP_Pulse();

			if (Player != nullptr)
				Player.SetCapabilityAttributeValue(n"AudioRespawnProgress", RespawnProgress);

			if (RespawnProgress >= 1.f)
				BP_HiddenFromFinished();
		}
		else if (bStarted)
		{
			bStarted = false;
		}

		// Update wheel
		if (DynamicMaterial != nullptr)
		{
			if (DisplayedProgress != RespawnProgress)
			{
				DynamicMaterial.SetScalarParameterValue(n"Progress", RespawnProgress);
				DisplayedProgress = RespawnProgress;
			}

			float NewSuccess = 0.f;
			if (RespawnComp.bRespawnMashPulse)
				NewSuccess = 1.f;
			else
				NewSuccess = FMath::FInterpConstantTo(DisplayedSuccess, 0.f, DeltaTime, 1.f / SuccessDisplayDuration);

			if (NewSuccess != DisplayedSuccess)
			{
				DynamicMaterial.SetScalarParameterValue(n"Success", NewSuccess);
				DisplayedSuccess = NewSuccess;
			}
		}
	}
};