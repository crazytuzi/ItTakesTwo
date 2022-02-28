import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.XylophoneRoom.XylophoneHammer;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.XylophoneRoom.XylophoneBar;
import Peanuts.Aiming.AutoAimTarget;

class AXylophoneKey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY()
	TArray<AXylophoneHammer> ConnectedXylophoneHammerArray;
	
	UPROPERTY()
	TArray<AXylophoneBar> ConnectedXylophoneBarArray;
	
	UPROPERTY()
	FHazeTimeLike MoveKeyTimeline;
	default MoveKeyTimeline.Duration = 0.4f;
	
	FRotator StartingRotation = FRotator::ZeroRotator;
	FRotator TargetRotation = FRotator(-15.f, 0.f, 0.f);
	FRotator ActualTargetRotation;
	
	float XylophoneBarActivationDelay = 0.15f;

	bool bXylophoneActivated = false;
	bool bReverseTargetRot = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveKeyTimeline.BindUpdate(this, n"MoveKeyTimelineUpdate");
		
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		if (!bXylophoneActivated)
			return;

		XylophoneBarActivationDelay -= DeltaTime;

		if (XylophoneBarActivationDelay <= 0.f)
		{
			for (AXylophoneBar Bar : ConnectedXylophoneBarArray)
			{
				Bar.ActivateXylophoneBar();
			}
			XylophoneBarActivationDelay = 0.15f;
			bXylophoneActivated = false;
		}
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		bXylophoneActivated = true;
		
		FVector HitDirection = (FVector(ActorLocation.X, ActorLocation.Y, 0.f) - FVector(HitInfo.HitLocation.X, HitInfo.HitLocation.Y, 0.f));
		ActualTargetRotation =  HitDirection.DotProduct(ActorUpVector) < 0.f ? TargetRotation : TargetRotation * -1;
		
		MoveKeyTimeline.PlayFromStart();

		for (AXylophoneHammer Hammer : ConnectedXylophoneHammerArray)
		{
			Hammer.ActivateXylophoneHammer();
		}
	}

	UFUNCTION()
	void MoveKeyTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRotation, ActualTargetRotation, CurrentValue));
	}	
}