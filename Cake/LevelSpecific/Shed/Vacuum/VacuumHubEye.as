UCLASS(Abstract)
class AVacuumHubEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent EyeMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent SplashEffect;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealTimeLike;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RevealEyeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HideEyeAudioEvent;

	UPROPERTY()
	float RevealDistance = 1200.f;

	bool bRevealing = false;

	float RotationOffset;
	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RevealTimeLike.SetPlayRate(2.f);
		RevealTimeLike.BindUpdate(this, n"UpdateReveal");
		RevealTimeLike.BindFinished(this, n"FinishReveal");

		RotationSpeed = FMath::RandRange(16.f, 32.f);
		RotationOffset = FMath::RandRange(1.f, 3.f);
	}

	void RevealEye()
	{
		if (bRevealing)
			return;

		bRevealing = true;
		RevealTimeLike.Play();

		SplashEffect.Activate(true);

		UHazeAkComponent::HazePostEventFireForget(RevealEyeAudioEvent, EyeMesh.GetWorldTransform());
	}

	void HideEye()
	{
		if (!bRevealing)
			return;

		bRevealing = false;
		RevealTimeLike.Reverse();

		UHazeAkComponent::HazePostEventFireForget(HideEyeAudioEvent, EyeMesh.GetWorldTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateReveal(float CurValue)
	{
		float CurHeight = FMath::Lerp(-150.f, 0.f, CurValue);
		EyeMesh.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishReveal()
	{
		if (!bRevealing)
			SplashEffect.Activate(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer;

		float DistanceToMay = GetDistanceTo(Game::GetMay());
		float DistanceToCody = GetDistanceTo(Game::GetCody());

		if (DistanceToMay <= RevealDistance || DistanceToCody <= RevealDistance)
		{
			HideEye();
			return;
		}

		if (DistanceToMay <= DistanceToCody)
			ClosestPlayer = Game::GetMay();
		else
			ClosestPlayer = Game::GetCody();

		RevealEye();

		FVector DirToPlayer = ClosestPlayer.ActorLocation - ActorLocation;
		DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
		DirToPlayer = DirToPlayer.GetSafeNormal();

		FRotator CurRot = FMath::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, 5.f);
		SetActorRotation(CurRot);

		float Rot = System::GetGameTimeInSeconds() * RotationSpeed;
		Rot += RotationOffset;
		Rot = FMath::Sin(Rot);
		Rot *= RotationOffset;

		EyeMesh.SetRelativeRotation(FRotator(0.f, 180.f, Rot));
	}
}