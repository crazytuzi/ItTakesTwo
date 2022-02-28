import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
class ASpinningVinylActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent ImpactComp;

	FVector StartForward;
	float SpinSpeed;
	float Friction = 0.9999f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartForward = ActorForwardVector;
		ImpactComp.OnCymbalHit.AddUFunction(this, n"OnCymbalHit");
	}

	UFUNCTION()
	void OnCymbalHit(FCymbalHitInfo HitInfo)
	{
		FVector HitDir = HitInfo.DeltaMovement.GetSafeNormal();

		if (StartForward.DotProduct(HitDir) > 0)
		{
			SpinSpeed -= 20;
		}

		else
		{
			SpinSpeed += 20;
		}

		SpinSpeed = FMath::Clamp(SpinSpeed, - 40, 40);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		//FRotator Rotation = Mesh.WorldRotation;
		FRotator Rotation;
		Rotation.Yaw += SpinSpeed *  Deltatime;

		SpinSpeed -= Deltatime;

		AddActorLocalRotation(Rotation);
	}
}