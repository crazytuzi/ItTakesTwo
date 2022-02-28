import Cake.LevelSpecific.SnowGlobe.Magnetic.CounterWeight.CounterWeightActor;
import Peanuts.Spline.SplineComponent;

class ACounterWeightFollowerLid : AHazeActor
{
	UPROPERTY()
	ACounterWeightActor ActorToFollow;


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent,  Attach = Root)
	UStaticMeshComponent DesiredRotationReference;

	default DesiredRotationReference.bHiddenInGame = true;
	default Mesh.bHiddenInGame = false;

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = Mesh.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FRotator DesiredRotation = DesiredRotationReference.RelativeRotation;
		Mesh.SetRelativeRotation(FMath::LerpShortestPath(StartRotation, DesiredRotation, ActorToFollow.Progress));
	}
}