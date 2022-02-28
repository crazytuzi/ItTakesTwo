import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

event void FOnSongOfLifeActivated();
UCLASS(Abstract)
class AMetronome : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MetronomeBase;

	UPROPERTY(DefaultComponent, Attach = MetronomeBase)
	USceneComponent StickBase;

	UPROPERTY(DefaultComponent, Attach = StickBase)
	UStaticMeshComponent StickMesh;

	UPROPERTY(DefaultComponent, Attach = StickBase)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongOfLifeComponent SongOfLifeComp;

	UPROPERTY()
	FOnSongOfLifeActivated OnSongOfLifeActivated;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveStickTimeLike;
	default MoveStickTimeLike.bLoop = true;
	default MoveStickTimeLike.bSyncOverNetwork = true;
	default MoveStickTimeLike.SyncTag = n"Metronome";

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StartAlpha = 0.25f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float CurRot = MoveStickTimeLike.Curve.ExternalCurve.GetFloatValue(StartAlpha);
		FQuat CurStickRot = FQuat::Slerp(FQuat(FRotator(43.f, -14.f, -19.f)), FQuat(FRotator(-43.f, 14.f, -19.f)), CurRot);
		StickBase.SetRelativeRotation(CurStickRot.Rotator());
		Platform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveStickTimeLike.SetNewTime(StartAlpha);
		MoveStickTimeLike.SetPlayRate(0.5f);
		MoveStickTimeLike.BindUpdate(this, n"UpdateMoveStick");
		
		SongOfLifeComp.OnStartAffectedBySongOfLife.AddUFunction(this, n"StartAffectedBySongOfLife");
		SongOfLifeComp.OnStopAffectedBySongOfLife.AddUFunction(this, n"StopAffectedBySongOfLife");
	}

	UFUNCTION()
	void StartAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		MoveStickTimeLike.PlayWithAcceleration(0.3f);
		OnSongOfLifeActivated.Broadcast();
	}

	UFUNCTION()
	void StopAffectedBySongOfLife(FSongOfLifeInfo Info)
	{
		MoveStickTimeLike.StopWithDeceleration(0.3f);
	}

	UFUNCTION()
	void UpdateMoveStick(float CurValue)
	{
		FQuat CurStickRot = FQuat::Slerp(FQuat(FRotator(43.f, -14.f, -19.f)), FQuat(FRotator(-43.f, 14.f, -19.f)), CurValue);
		StickBase.SetRelativeRotation(CurStickRot.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Platform.SetWorldRotation(FRotator(0.f, ActorRotation.Yaw, 0.f));
	}
}