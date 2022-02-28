import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

UCLASS(Abstract)
class ALoudSpeaker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SpeakerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent SoundDirection;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent Trigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent PulseEffect;

	UCymbalComponent PlayerCymbalComp;

	bool bCodyShielding = false;

	bool bCodyAffected = false;
	bool bMayAffected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
		Trigger.OnComponentEndOverlap.AddUFunction(this, n"ExitTrigger");

		System::SetTimer(this, n"PlayPulseEffect", 1.f, true);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayPulseEffect()
	{
		PulseEffect.Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PlayerCymbalComp == nullptr)
		{
			PlayerCymbalComp = UCymbalComponent::Get(Game::GetCody());
			return;
		}

		float CodySideOffset = 0.f;
		float DistanceToCody = 0.f;
		float DistanceToMay = 0.f;

		if (bCodyAffected)
		{
			float Dot = Game::GetCody().ActorForwardVector.DotProduct(SoundDirection.ForwardVector);
			DistanceToCody = GetHorizontalDistanceTo(Game::GetCody());
				
			FVector Dif = ActorLocation - Game::GetCody().ActorLocation;
			Dif = Math::ConstrainVectorToDirection(Dif, ActorRightVector);
			CodySideOffset = FMath::Abs(Dif.Size());

			if (Dot < -0.9f && PlayerCymbalComp.bShieldActive)
			{
				bCodyShielding = true;
			}
			else
			{
				Game::GetCody().AddImpulse(SoundDirection.ForwardVector * 7000.f * DeltaTime);
				bCodyShielding = false;
			}
		}
		else
			bCodyShielding = false;

		if (bMayAffected)
		{
			FVector Dif = ActorLocation - Game::GetMay().ActorLocation;
			Dif = Math::ConstrainVectorToDirection(Dif, ActorRightVector);
			float MaySideOffset = FMath::Abs(Dif.Size());

			float SideOffsetDif = FMath::Abs(MaySideOffset - CodySideOffset);
			DistanceToMay = GetHorizontalDistanceTo(Game::GetMay());

			if (bCodyShielding && SideOffsetDif < 100.f && DistanceToMay > DistanceToCody && DistanceToMay - DistanceToCody < 750.f) 
			{

			}
			else
			{
				Game::GetMay().AddImpulse(SoundDirection.ForwardVector * 7000.f * DeltaTime);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player == Game::GetMay())
				bMayAffected = true;
			else
				bCodyAffected = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player == Game::GetMay())
				bMayAffected = false;
			else
				bCodyAffected = false;
		}
	}
}