import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkLastBossRecordCrusherClockFace;
class AClockworkLastBossRecordCrusherClockHolder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh2;

	UPROPERTY()
	AClockworkLastBossRecordCrusherClockFace ConnectedClockface;

	UPROPERTY()
	FHazeTimeLike MoveHolderForwardTimeline;
	
	UPROPERTY()
	FHazeTimeLike MoveHolderDownTimeline;

	UPROPERTY()
	float StartingDelay = 0.f;

	UPROPERTY()
	float ForwardOffset = 8000.f;

	float ForwardDelay = 1.0f;
	float DownDelay = 1.f;

	bool bTickForwardDelay = false;
	bool bTickDownDelay = false;

	bool bShouldTickStartDelay = false;

	FVector ForwardStartingLoc;
	FVector ForwardTargetLoc;
	FVector DownStartingLoc;
	FVector DownTargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveHolderForwardTimeline.BindUpdate(this, n"MoveHolderForwardTimelineUpdate");
		MoveHolderForwardTimeline.BindFinished(this, n"MoveHolderForwardTimelineFinished");
		MoveHolderDownTimeline.BindUpdate(this, n"MoveHolderDownTimelineUpdate");
		MoveHolderDownTimeline.BindFinished(this, n"MoveHolderDownTimelineFinished");

		ForwardStartingLoc = GetActorLocation();
		ForwardTargetLoc = ForwardStartingLoc + (GetActorForwardVector() * ForwardOffset);
		DownStartingLoc = ForwardTargetLoc;
		DownTargetLoc = DownStartingLoc + (GetActorUpVector() * -1000.f);

		ConnectedClockface.AttachToActor(this, n"", EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bContinueTicking = false;

		if (bShouldTickStartDelay)
		{
			StartingDelay -= DeltaTime;
			bContinueTicking = true;
			if (StartingDelay <= 0.f)
			{
				MoveHolderForwardTimeline.PlayFromStart();
				bShouldTickStartDelay = false;
			}
		}

		if (bTickForwardDelay)
		{
			ForwardDelay -= DeltaTime;
			bContinueTicking = true;
			if (ForwardDelay <= 0.f)
			{
				bTickForwardDelay = false;
				MoveHolderDownTimeline.PlayFromStart();
			}
		}

		if (bTickDownDelay)
		{
			DownDelay -= DeltaTime;
			bContinueTicking = true;
			if (DownDelay <= 0.f)
			{
				bTickDownDelay = false;
				MoveHolderDownTimeline.ReverseFromEnd();
			}
		}

		if (!bContinueTicking)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void StartMovingHolder()
	{
		bShouldTickStartDelay = true;
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
		ConnectedClockface.SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void MoveHolderForwardTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::Lerp(ForwardStartingLoc, ForwardTargetLoc, CurrentValue));
	}

	UFUNCTION()
	void MoveHolderForwardTimelineFinished(float CurrentValue)
	{
		if (CurrentValue > 0.f)
		{
			bTickForwardDelay = true;
			SetActorTickEnabled(true);
		}

		if (CurrentValue <= 0.f)
			SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void MoveHolderDownTimelineUpdate(float CurrentValue)
	{
		SetActorLocation(FMath::Lerp(DownStartingLoc, DownTargetLoc, CurrentValue));
	}

	UFUNCTION()
	void MoveHolderDownTimelineFinished(float CurrentValue)
	{
		if (CurrentValue > 0.f)
		{
			bTickDownDelay = true;
			SetActorTickEnabled(true);
			ConnectedClockface.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		if (CurrentValue <= 0.f)
			MoveHolderForwardTimeline.ReverseFromEnd();
	}

	UFUNCTION()
	void SetClockToTargetPosition(bool bClockShouldBeDestroyed)
	{
		SetActorLocation(DownTargetLoc);
		ConnectedClockface.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ConnectedClockface.SetActorHiddenInGame(false);
		
		if (HasControl())
		{
			if (bClockShouldBeDestroyed)
				ConnectedClockface.NetDestroyClockFace(false);
		}
	}
}