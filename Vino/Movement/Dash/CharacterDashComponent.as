import Peanuts.Animation.Features.LocomotionFeatureDashWallHit;
class UCharacterDashComponent : UActorComponent
{
	float DashActiveDuration = BIG_NUMBER;
	float DashDeactiveDuration = BIG_NUMBER;
	
	bool bDashActive = false;
	bool bDashEnded = false;
	bool bFailedPerfectDashWindow = true;

	UPROPERTY(Category = "Dash")
	UForceFeedbackEffect DashForceFeedback;
	UPROPERTY(Category = "Dash")
    TSubclassOf<UCameraShakeBase> DashCameraShake;
	UPROPERTY(Category = "Dash")
	UNiagaraSystem DashEffect;

	UPROPERTY(Category = "Dash Jump")
	UForceFeedbackEffect DashJumpForceFeedback;
	UPROPERTY(Category = "Dash Jump")
    TSubclassOf<UCameraShakeBase> DashJumpCameraShake;
	UPROPERTY(Category = "Dash Jump")
	UNiagaraSystem DashJumpEffect;

	UPROPERTY(Category = "Perfect Dash")
	UForceFeedbackEffect PerfectDashForceFeedback;
	UPROPERTY(Category = "Perfect Dash")
    TSubclassOf<UCameraShakeBase> PerfectDashCameraShake;
	UPROPERTY(Category = "Perfect Dash")
	UNiagaraSystem PerfectDashEffect;

	UPROPERTY()
	FHazeHitResult PredictedHit;
	bool bHasWallHitFeature = false;

	AHazePlayerCharacter OwningPlayer = nullptr; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		OwningPlayer.Mesh.OnFeatureListChanged.AddUFunction(this, n"OnFeatureListChanged");

		OnFeatureListChanged();
	}

	UFUNCTION()
	void OnFeatureListChanged()
	{
		bHasWallHitFeature = ULocomotionFeatureDashWallHit::Get(OwningPlayer) != nullptr;
	}

	bool ConsumeDashEnded()
	{
		if (bDashEnded)
		{
			bDashEnded = false;
			return true;
		}

		return false;
	}

}
