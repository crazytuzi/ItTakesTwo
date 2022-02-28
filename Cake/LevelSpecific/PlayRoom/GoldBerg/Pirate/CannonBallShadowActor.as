UCLASS(Abstract)
class ACannonBallShadowActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent MiddleMesh;
	default MiddleMesh.CastShadow = false;
	default MiddleMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

    FVector TargetLocation;	
	
	void Activate(FVector CannonTargetLocation)
	{
		TargetLocation = CannonTargetLocation;
		SetActorLocation(TargetLocation);
		ScaleLinesWithDistance(0.f);
	}

	void ScaleLinesWithDistance(float NewAlpha)
	{
		const FVector CurrentScale = FMath::Lerp(FVector(.65f, .65f, .65f), FVector::OneVector, NewAlpha);
	
		MiddleMesh.SetRelativeScale3D(CurrentScale);

        MiddleMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", NewAlpha);
	}

}