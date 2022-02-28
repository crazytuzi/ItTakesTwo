import Peanuts.Spline.SplineComponent;
import Cake.Environment.Breakable;

class AClockworkLastBossFallingDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.bHiddenInGame = true;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;

	UPROPERTY()
	ABreakableActor ConnectedBreakable;

	UPROPERTY(Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewScrubValue = 0.f;

	UPROPERTY()
	float MoveDuration = 5.f;

	UPROPERTY()
	UNiagaraSystem ExplosionFX;

	UPROPERTY()
	UForceFeedbackEffect DestroyForceFeedback;

	UPROPERTY()
	bool bCodyToRecieveCamShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	FVector CurrentVelocity = FVector::ZeroVector;

	bool bHasDestroyedBreakable = false;
	bool bShouldMoveDebris = false;

	float CurrentDistance = 0.f;
	
	UPROPERTY()
	float DestroyBreakableAtDistance = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoot.SetRelativeTransform(FTransform::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
		MeshRoot.SetRelativeTransform(Spline.GetTransformAtDistanceAlongSpline(Spline.GetSplineLength() * PreviewScrubValue, ESplineCoordinateSpace::Local));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldMoveDebris)
			return;

		CurrentDistance += (DeltaTime / MoveDuration);
		FVector LastLocation = MeshRoot.GetWorldLocation();
		
		MeshRoot.SetRelativeTransform(Spline.GetTransformAtDistanceAlongSpline(Spline.GetSplineLength() * CurrentDistance, ESplineCoordinateSpace::Local));

		CurrentVelocity = MeshRoot.GetWorldLocation() - LastLocation;

		if (Spline.GetSplineLength() * CurrentDistance >= DestroyBreakableAtDistance)
			DestroyBreakable();
	}

	UFUNCTION(NetFunction)
	void NetStartMovingDebris()
	{
		bShouldMoveDebris = true;
		Mesh.SetHiddenInGame(false);
	}

	UFUNCTION(CallInEditor)
	void SetLocationToDestroyBreakable()
	{
		DestroyBreakableAtDistance = Spline.GetDistanceAlongSplineAtWorldLocation(MeshRoot.WorldLocation);
	}

	void DestroyBreakable()
	{
		if (bHasDestroyedBreakable)
			return;
		
		bHasDestroyedBreakable = true;

		FBreakableHitData BreakData;
		BreakData.DirectionalForce = CurrentVelocity;
		BreakData.HitLocation = MeshRoot.GetWorldLocation();
		BreakData.ScatterForce = 5.f;
		ConnectedBreakable.BreakableComponent.Break(BreakData);

		SpawnFX();
		PlayCamShake();
		PlayerRumble();
	}

	void SpawnFX()
	{
		Niagara::SpawnSystemAtLocation(ExplosionFX, ConnectedBreakable.GetActorLocation(), FRotator::ZeroRotator);
	}

	void PlayCamShake()
	{
		AHazePlayerCharacter PlayerToRecieveCamShake = bCodyToRecieveCamShake ? Game::GetCody() : Game::GetMay(); 
		PlayerToRecieveCamShake.PlayCameraShake(CamShake);
	}

	void PlayerRumble()
	{
		if (DestroyForceFeedback != nullptr)
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				Player.PlayForceFeedback(DestroyForceFeedback, false, true, n"DestroyForceFeedback");
			}
		}
	}
}