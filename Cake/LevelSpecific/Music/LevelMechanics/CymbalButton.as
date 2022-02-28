import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnButtonActivated(bool bActive);

UCLASS(Abstract)
class ACymbalButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	UAutoAimTargetComponent AutoAimTargetComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 180.0f;

	UPROPERTY(Category = "Audio Event")
	UAkAudioEvent OnCymbalHitAudioEvent;

	UPROPERTY()
	FHazeTimeLike MoveButtonTimeline;
	default MoveButtonTimeline.Duration = 0.15f;

	UPROPERTY()
	FOnButtonActivated OnButtonActivated;

	UPROPERTY()
	FVector RedColor;

	UPROPERTY()
	FVector GreenColor;

	UPROPERTY()
	bool bResetAfterDuration = false;

	UPROPERTY()
	float ResetDuration = 1.f;

	float CurrentResetDuration = 0.f;
	bool bShouldTickResetDuration = false;

	bool bButtonWasHit = false;

	FVector StartLoc = FVector::ZeroVector;
	FVector TargetLoc = FVector(0.f, 0.f, -150.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
		MoveButtonTimeline.BindUpdate(this, n"MoveButtonTimelineUpdate");
		
		Mesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", RedColor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickResetDuration)
		{
			CurrentResetDuration -= DeltaTime;
			if (CurrentResetDuration <= 0.f)
			{
				bShouldTickResetDuration = false;
				MoveButtonTimeline.Reverse();
				bButtonWasHit = false;
				OnButtonActivated.Broadcast(false);
				ButtonToggled(false);
			}
		}
	}	

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if (bResetAfterDuration && bButtonWasHit)
			return;

		bButtonWasHit ? MoveButtonTimeline.Reverse() : MoveButtonTimeline.Play();
		bButtonWasHit = !bButtonWasHit;

		OnButtonActivated.Broadcast(bButtonWasHit);
		ButtonToggled(bButtonWasHit);

		if (bResetAfterDuration)
		{
			bShouldTickResetDuration = true;
			CurrentResetDuration = ResetDuration;
		}

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_World_Music_Backstage_Interactable_CymbalButton_ResetDuration", ResetDuration);
		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(OnCymbalHitAudioEvent, this.GetActorTransform(), Rtpcs);

	}

	UFUNCTION()
	void MoveButtonTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLoc, TargetLoc, CurrentValue));
		Mesh.SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", FMath::Lerp(RedColor, GreenColor, CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	void ButtonToggled(bool bButtonActive)
	{
	
	}
}