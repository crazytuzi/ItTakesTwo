import Peanuts.Spline.SplineComponent;
import Cake.Weapons.Sap.SapResponseComponent;

UCLASS(abstract)
class AQueenGrindSplineBlob : AHazeActor
{
	TArray<UStaticMeshComponent> Swarm;
	
	UPROPERTY()
	AHazeActor GrindSplineActor;

	UHazeSplineComponent GrindSpline;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent BoxCollider;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USapResponseComponent SapComponent;

	UPROPERTY()
	float HeightOffsetOverSpline;

	FHazeSplineSystemPosition Progress;

	UPROPERTY()
	float SplineSpeed;

	UPROPERTY()
	bool bFlyForward;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(Swarm);
		GrindSpline = UHazeSplineComponent::Get(GrindSplineActor);
		Progress = GrindSpline.GetPositionClosestToWorldLocation(ActorLocation, bFlyForward);
		SapComponent.OnSapExploded.AddUFunction(this, n"OnSapExploded");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Progress.Move(SplineSpeed * DeltaTime);

		FVector SplinePosition = Progress.WorldLocation;
		SplinePosition +=  FVector::UpVector * HeightOffsetOverSpline;

		SetActorRotation(Progress.WorldRotation);
		SetActorLocation(SplinePosition);
	}

	UFUNCTION()
	void OnSapExploded(FVector SapWorldLocation, USceneComponent AttachComponent, FName AttachSocket)
	{
		for (UStaticMeshComponent Mesh : Swarm)
		{
			Mesh.SetSimulatePhysics(true);
			Mesh.AddImpulse(Math::RandomPointOnSphere * 1000);
		}
		System::SetTimer(this, n"FinalDestroy", 4.f, bLooping=false);
	}

	UFUNCTION()
	void FinalDestroy()
	{
		DestroyActor();
	}
}