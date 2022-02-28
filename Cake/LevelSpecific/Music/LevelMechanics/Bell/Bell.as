import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnBellRung();

UCLASS(Abstract)
class ABell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BellMesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY()
	FOnBellRung OnBellRung;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateBellTimeLike;

	FVector HitDirection;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");

		RotateBellTimeLike.BindUpdate(this, n"UpdateRotateBell");
		RotateBellTimeLike.BindFinished(this, n"FinishRotateBell");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		HitDirection = (ActorLocation - HitInfo.HitLocation).GetSafeNormal();
		HitDirection = Math::ConstrainVectorToPlane(HitDirection, FVector::UpVector);
		OnBellRung.Broadcast();
		TargetRotation = FRotator(HitDirection.X * 30.f, 0.f, -HitDirection.Y * 30.f);
		RotateBellTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotateBell(float CurValue)
	{
		FRotator CurRot = FMath::LerpShortestPath(FRotator::ZeroRotator, TargetRotation, CurValue);
		SetActorRotation(CurRot);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotateBell()
	{

	}
}