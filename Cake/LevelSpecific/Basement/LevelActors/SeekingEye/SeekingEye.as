import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;


event void FOnSeekingEyeScanPointReached(AActor ScanPoint);
event void FOnSeekingEyeRevealed();

UCLASS(Abstract)
class ASeekingEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase MonsterMesh;

	UPROPERTY(DefaultComponent, Attach = MonsterMesh, AttachSocket = InnerSkull)
	USceneComponent ScanOrigin;

	UPROPERTY(DefaultComponent, Attach = ScanOrigin)
	USpotLightComponent SearchLight;

	UPROPERTY(DefaultComponent, Attach = ScanOrigin)
	UStaticMeshComponent VisionCone;

	UPROPERTY(DefaultComponent, Attach = ScanOrigin)
	UNiagaraComponent ChargeEffect;

	UPROPERTY(DefaultComponent, Attach = ScanOrigin)
	UNiagaraComponent PushEffect;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealTimelLike;

	UPROPERTY()
	TArray<AActor> ScanPoints;

	UPROPERTY()
	FOnSeekingEyeScanPointReached OnScanPointReached;

	UPROPERTY()
	FOnSeekingEyeRevealed OnSeekingEyeRevealed;

	bool bScanningAllowed = false;

	AActor CurrentScanPoint;

	UPROPERTY()
	int CurrentScanIndex = 1;

	UPROPERTY()
	float ScanRotationSpeed = 15.f;

	UPROPERTY()
	float StopTimeAtScanPoint = 3.f;

	bool bIncrementing = true;
	bool bPlayersInCone = false;
	bool bFollowingPlayers = false;
	bool bRevealed = false;
	bool bActive = false;

	FVector StartLoc;

	UPROPERTY()
	float EndHeight = 4000.f;

	UPROPERTY()
	float RevealDuration = 2.f;

	UPROPERTY()
	bool bAllowPushback = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ScanPoints.Num() == 1)
			CurrentScanIndex = 0;

		AddCapability(n"SeekingEyeFollowPlayersCapability");
		AddCapability(n"SeekingEyeScanCapability");
		AddCapability(n"SeekingEyePostFollowCapability");

		VisionCone.OnComponentBeginOverlap.AddUFunction(this, n"EnterCone");
		VisionCone.OnComponentEndOverlap.AddUFunction(this, n"ExitCone");

		RevealTimelLike.BindUpdate(this, n"UpdateReveal");
		RevealTimelLike.BindFinished(this, n"FinishReveal");

		StartLoc = ActorLocation;

		RevealTimelLike.SetPlayRate(1.f/RevealDuration);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void RevealSeekingEye()
	{
		if (bRevealed)
			return;

		bRevealed = true;
		RevealTimelLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateReveal(float CurValue)
	{
		float CurVerticalLoc = FMath::Lerp(StartLoc.Z, StartLoc.Z + EndHeight, CurValue);
		SetActorLocation(FVector(ActorLocation.X, ActorLocation.Y, CurVerticalLoc));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishReveal()
	{
		OnSeekingEyeRevealed.Broadcast();
		bActive = true;
	}

	UFUNCTION()
	void AllowScanning()
	{
		bScanningAllowed = true;
	}

	UFUNCTION()
	void DisallowScanning()
	{
		bScanningAllowed = false;
	}

	UFUNCTION()
	void UpdateScanPoints(TArray<AActor> NewScanPoints, int NewIndex)
	{
		CurrentScanIndex = NewIndex;
		ScanPoints = NewScanPoints;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterCone(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob != nullptr)
		{
			bPlayersInCone = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitCone(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob != nullptr)
		{
			bPlayersInCone = false;
		}
	}

	void PlayersSpotted()
	{

	}

	void PlayersUnspotted()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayersSpotted() {}

	UFUNCTION(BlueprintEvent)
	void BP_PlayersUnspotted() {}
}