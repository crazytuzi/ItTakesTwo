import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;

event void FOnSpinnerSpun();

class ASilentRoomSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpinAudioEvent;

	UPROPERTY()
	FOnSpinnerSpun OnSpinnerSpun;

	bool bShouldSpin = false;
	float SpinTimer = 0.f;

	float TotalRotationToAdd = 1080.f;
	float RotationSpeed = 450.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldSpin)
		{
			SpinTimer += DeltaTime;
			if (SpinTimer <= TotalRotationToAdd/RotationSpeed)
			{
				float MeshRootYaw = FMath::EaseOut(0.f, TotalRotationToAdd, SpinTimer/(TotalRotationToAdd/RotationSpeed), 2.f);
				MeshRoot.SetRelativeRotation(FRotator(0.f, MeshRootYaw, 0.f));
			} else
			{
				bShouldSpin = false;
				MeshRoot.SetRelativeRotation(FRotator::ZeroRotator);
			}
		}
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if (!bShouldSpin)
		{
			SpinTimer = 0.f;
			bShouldSpin = true;
			OnSpinnerSpun.Broadcast();
			UHazeAkComponent::HazePostEventFireForget(SpinAudioEvent, this.GetActorTransform());
		}
	}
}