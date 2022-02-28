import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.BouncePad.BouncePad;
import Cake.LevelSpecific.Shed.Vacuum.VacuumFlipPlatformBouncePad;

UCLASS(Abstract)
class AVacuumFlipPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	UAkAudioEvent FlipAudioEvent;

	UPROPERTY()
	AVacuumFlipPlatformBouncePad TopBouncePad;

	UPROPERTY()
	AVacuumFlipPlatformBouncePad BottomBouncePad;

	UPROPERTY()
	bool bFlipping = false;

	UPROPERTY()
	bool bFlipped = false;

	UPROPERTY()
	FHazeTimeLike FlipTimeLike;
	default FlipTimeLike.Duration = 0.25f;

	bool bFrontFlip = true;
	float StartRotation = 0.f;
	float EndRotation = 90.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TopBouncePad != nullptr)
		{
			TopBouncePad.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			TopBouncePad.SetActorRelativeLocation(FVector(0.f, 600.f, 20.f), false, FHitResult(), true);
			TopBouncePad.SetActorRelativeRotation(FRotator::ZeroRotator, false, FHitResult(), true);
			TopBouncePad.SetActorScale3D(FVector(6.5f, 6.5f, 0.25f));
			TopBouncePad.BouncePadMesh.SetCastShadow(false);
			TopBouncePad.SetActorHiddenInGame(true);
		}
		if (BottomBouncePad != nullptr)
		{
			BottomBouncePad.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			BottomBouncePad.SetActorRelativeLocation(FVector(0.f, -20.f, -600.f), false, FHitResult(), true);
			BottomBouncePad.SetActorRelativeRotation(FRotator(0.f, 0.f, -90.f), false, FHitResult(), true);
			BottomBouncePad.SetActorScale3D(FVector(6.5f, 6.5f, 0.25f));
			BottomBouncePad.BouncePadMesh.SetCastShadow(false);
			BottomBouncePad.SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TopBouncePad.OnBounced.AddUFunction(this, n"Bounce");
		BottomBouncePad.OnBounced.AddUFunction(this, n"Bounce");

		SetDisableStatus(true);

		FlipTimeLike.BindUpdate(this, n"UpdateFlip");
		FlipTimeLike.BindFinished(this, n"FinishFlip");
	}

	UFUNCTION(NotBlueprintCallable)
	void Bounce(AHazePlayerCharacter Player, ABouncePad BouncePad)
	{
		if (FlipTimeLike.IsPlaying())
			return;

		if (BouncePad == BottomBouncePad && bFrontFlip)
			return;

		if (BouncePad == TopBouncePad && !bFrontFlip)
			return;

		bFrontFlip = !bFrontFlip;
		StartRotation = bFrontFlip ? 90.f : 0.f;
		EndRotation = bFrontFlip ? 0.f : 90.f;

		HazeAkComp.HazePostEvent(FlipAudioEvent);
		FlipTimeLike.PlayFromStart();

		int WobbleIndex = bFrontFlip ? 2 : 0;
		PlatformMesh.SetScalarParameterValueOnMaterialIndex(WobbleIndex, n"SpeakerVibrateMultiplier", 1.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFlip(float CurValue)
	{
		float Rot = FMath::Lerp(StartRotation, EndRotation, CurValue);
		PlatformRoot.SetRelativeRotation(FRotator(0.f, 0.f, Rot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishFlip()
	{


		PlatformMesh.SetScalarParameterValueOnMaterials(n"SpeakerVibrateMultiplier", 0.f);
	}

	UFUNCTION()
	void SetDisableStatus(bool bDisable)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor CurActor : AttachedActors)
		{
			AHazeActor CurHazeActor = Cast<AHazeActor>(CurActor);
			if (CurHazeActor != nullptr)
			{
				if (bDisable)
				{
					if (!CurHazeActor.IsActorDisabled())
						CurHazeActor.DisableActor(this);
				}
				else
				{
					if (CurHazeActor.IsActorDisabled())
						CurHazeActor.EnableActor(this);
				}
			}
		}

		if (bDisable)
		{
			if (!IsActorDisabled(this))
				DisableActor(this);
		}
		else
		{
			if (IsActorDisabled())
				EnableActor(this);
		}
	}
}