import Vino.Triggers.PlayerLookAtTriggerComponent;

UCLASS(Abstract)
class AOilCanCreature : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UPlayerLookAtTriggerComponent LookatTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealTimeLike;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent UpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DownAudioEvent;

	UPROPERTY()
	float RevealDistance = 1200.f;

	UPROPERTY()
	float HideDistance = 600.f;

	bool bRevealing = false;

	float RotationOffset;
	float RotationSpeed;

	UFUNCTION()
	bool GetIsRevealing()
	{
		return bRevealing;
	}

	UFUNCTION(BlueprintEvent)
	void OnReveal()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void OnHide()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RevealTimeLike.SetPlayRate(2.f);
		RevealTimeLike.BindUpdate(this, n"UpdateReveal");
		RevealTimeLike.BindFinished(this, n"FinishReveal");

		EyeMesh.SetRelativeLocation(FVector(0.f, 0.f, -150.f));

		RotationSpeed = FMath::RandRange(4.f, 8.f);
		RotationOffset = FMath::RandRange(0.75f, 1.5f);
	}

	void RevealEye()
	{
		if (bRevealing)
			return;

		bRevealing = true;
		RevealTimeLike.Play();

		SplashEffect.Activate(true);
		HazeAkComp.HazePostEvent(UpAudioEvent);
		OnReveal();
	}

	void HideEye()
	{
		if (!bRevealing)
			return;

		bRevealing = false;
		RevealTimeLike.Reverse();
		OnHide();
		HazeAkComp.HazePostEvent(DownAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateReveal(float CurValue)
	{
		float CurHeight = FMath::Lerp(-70.f, 0.f, CurValue);
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

		if (DistanceToMay >= RevealDistance && DistanceToCody >= RevealDistance ||
			DistanceToMay <= HideDistance || DistanceToCody <= HideDistance)
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
		DirToPlayer *= -1;

		FRotator CurRot = FMath::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, 5.f);
		SetActorRotation(CurRot);

		float Rot = System::GetGameTimeInSeconds() * RotationSpeed;
		Rot += RotationOffset;
		Rot = FMath::Sin(Rot);
		Rot *= RotationOffset;

		EyeMesh.SetRelativeRotation(FRotator(0.f, 180.f, Rot));
	}
}