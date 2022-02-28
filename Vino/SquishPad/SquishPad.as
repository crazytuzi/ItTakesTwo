import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class ASquishPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SquishMesh;
	default SquishMesh.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Hopscotch/Whoopee_Cushion_01.Whoopee_Cushion_01");

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	FVector SquishScale = FVector(1.1f, 1.1f, 0.75f);
	FVector DefaultScale = FVector::OneVector;

	UPROPERTY(NotEditable)
	FHazeTimeLike SquishTimeLike;
	default SquishTimeLike.Duration = 1.f;
	default SquishTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelMechanics/SquishPad/SquishPadCurve.SquishPadCurve");

	UPROPERTY()
	float SquishDuration = 0.25f;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent SquishAudioEvent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Mesh != nullptr)
		{
			SquishMesh.SetStaticMesh(Mesh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"Impact");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"NoImpact");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		SquishTimeLike.SetPlayRate(1.f/SquishDuration);
		SquishTimeLike.BindUpdate(this, n"UpdateSquish");

		DefaultScale = SquishMesh.RelativeScale3D;
	}

	UFUNCTION(NotBlueprintCallable)
	void Impact(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (SquishTimeLike.IsPlaying())
			SquishTimeLike.Reverse();
		else if (SquishTimeLike.IsReversed())
			SquishTimeLike.Play();
		else
			SquishTimeLike.PlayFromStart();

		if (SquishAudioEvent != nullptr)
			HazeAkComp.HazePostEvent(SquishAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void NoImpact(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateSquish(float CurValue)
	{
		FVector CurScale = FMath::Lerp(DefaultScale, SquishScale, CurValue);
		SquishMesh.SetRelativeScale3D(CurScale);
	}
}