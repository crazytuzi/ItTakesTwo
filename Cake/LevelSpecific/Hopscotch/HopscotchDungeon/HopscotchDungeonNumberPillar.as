import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Bounce.BounceComponent;
import Peanuts.Audio.AudioStatics;
event void FPlayerLandedOnPillar(AHazePlayerCharacter Player, int PillarNumber, AHopscotchDungeonNumberPillar Pillar);

class AHopscotchDungeonNumberPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent MeshCube01;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent MeshCube02;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent MeshCube03;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent MeshCube04;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = TopMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PillarMoveUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PillarMoveDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PillarReachTopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PillarReachBottomAudioEvent;

	// UPROPERTY(DefaultComponent, Attach = BounceRoot)
	// UBounceComponent BounceComp; 

	//HazeAkComp.HazePostEvent(AudioImpact.AudioEvent);

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	FPlayerLandedOnPillar PlayerLandedOnPillarEvent;

	UPROPERTY()
	FHazeTimeLike MovePillarTimeline;
	default MovePillarTimeline.Duration = 1.f;

	UPROPERTY()
	TArray<UMaterialInstance> CubeMaterialArray;

	UPROPERTY()
	TArray<UMaterialInstance> NumberMaterialArray;

	UPROPERTY()
	UStaticMesh NumberCube;

	UPROPERTY()
	UStaticMesh PlainCube;

	UPROPERTY()
	int Number = 1;

	UPROPERTY()
	bool bStartUp = false;

	bool bPillarIsUp = false;

	float MoveDelayTimer = 0.f;
	bool bShouldTickMoveDelayTimer = false;
	bool bShouldMoveForward = false;
	bool bDidMove = false;

	FVector StartLocation = FVector(0.f, 0.f, -2500.f);
	FVector TargetLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovePillarTimeline.BindUpdate(this, n"MovePillarTimelineUpdate");
		MovePillarTimeline.BindFinished(this, n"MovePillarTimelineFinished");
		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnPillar");

		if (!bStartUp)
			MeshRoot.SetRelativeLocation(StartLocation);
		else
			MovePillarTimeline.SetNewTime(1.f);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Number == 0)
		{
			TopMesh.SetStaticMesh(PlainCube);
			TopMesh.SetMaterial(0, CubeMaterialArray[0]);
		}
		else
		{
			TopMesh.SetStaticMesh(NumberCube);
			TopMesh.SetMaterial(0, CubeMaterialArray[1]);
		}
		
		if (Number != 0)
			TopMesh.SetMaterial(1, NumberMaterialArray[Number]);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bShouldTickMoveDelayTimer)
		{
			MoveDelayTimer -= DeltaTime;
			if (MoveDelayTimer <= 0.f)
			{
				bShouldTickMoveDelayTimer = false;
				bShouldMoveForward ? MovePillarTimeline.Play() : MovePillarTimeline.Reverse(); 

				if (bShouldMoveForward && MovePillarTimeline.GetValue() == 1.f)
					return;
				else if (!bShouldMoveForward && MovePillarTimeline.GetValue() == 0.f)
					return;
				else if (bShouldMoveForward)
				{
					AudioPostMoveUp();
					bDidMove = true;
				}
				else if (!bShouldMoveForward)
				{
					AudioPostMoveDown();
					bDidMove = true;
				}
			}
		}
	}

	UFUNCTION()
	void MovePillarTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	void MovePillarTimelineFinished(float CurrentValue)
	{
		if (bDidMove)
		{
			bDidMove = false;

			if (CurrentValue == 1)
			{
				HazeAkComp.HazePostEvent(PillarReachTopAudioEvent);
			}
			else
				HazeAkComp.HazePostEvent(PillarReachBottomAudioEvent);
		}
	}

	UFUNCTION()
	void MovePillar(bool bForward, float TimelineDuration, float MoveDelay)
	{
		MovePillarTimeline.SetPlayRate(1/TimelineDuration);
		bPillarIsUp = bForward;
		bShouldMoveForward = bForward;
		MoveDelayTimer = MoveDelay;
		bShouldTickMoveDelayTimer = true;
	}

	UFUNCTION()
	void AudioPostMoveUp()
	{
		HazeAkComp.HazePostEvent(PillarMoveUpAudioEvent);
	}

	UFUNCTION()
	void AudioPostMoveDown()
	{
		HazeAkComp.HazePostEvent(PillarMoveDownAudioEvent);	
	}

	UFUNCTION()
	void PlayerLandedOnPillar(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		PlayerLandedOnPillarEvent.Broadcast(Player, Number, this);
	}
}