import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FFearSeekerEvent();
event void FFearSeekerSpotEvent(float DamageSpeed);
event void FFearSeekerScanPointEvent(AActor ScanPoint);

UCLASS(Abstract)
class AFearSeeker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SeekerMesh;

	UPROPERTY(DefaultComponent, Attach = SeekerMesh, AttachSocket = Head)
	UArrowComponent SearchRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BeamComp;

	UPROPERTY()
	FFearSeekerSpotEvent OnSpottedByFearSeeker;

	UPROPERTY()
	FFearSeekerEvent OnUnspottedByFearSeeker;

	UPROPERTY()
	FFearSeekerScanPointEvent OnScanPointReached;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SpottedCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SpottedRumble;

	bool bScanSpotPlayers = false;
	UPROPERTY(BlueprintReadOnly)
	bool bPlayerSpotted = false;
	bool bScanning = false;

	UPROPERTY()
	float MaxRange = 3000.f;

	UPROPERTY()
	float StopTimeAtScanPoint = 1.f;

	UPROPERTY()
	TArray<AActor> ScanPoints;

	UPROPERTY()
	float ScanRotationSpeed = 22.f;

	UPROPERTY()
	bool bRotateTowardsPlayers = true;

	UPROPERTY()
	bool bTrackPlayersUsingSideOffset = false;

	UPROPERTY()
	float DamageSpeed = 0.25f;

	int CurrentScanIndex = 1;
	bool bIncrementingScan = true;

	UPROPERTY()
	bool bLedge = false;
	UPROPERTY(BlueprintReadOnly)
	bool bLedgeLeft = false;
	bool bLedgeTracking = false;
	float TimeSpentNotSpottingPlayers = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// AddCapability(n"FearSeekerScanCapability");
		// AddCapability(n"FearSeekerFollowPlayersCapability");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/*if (bLedge && bLedgeTracking && bScanSpotPlayers)
		{
			if (!bLedgeLeft)
			{
				if (bPlayerSpotted)
					TimeSpentNotSpottingPlayers = 0.f;

				TimeSpentNotSpottingPlayers += DeltaTime;
				if (TimeSpentNotSpottingPlayers >= 5.f)
				{
					bLedgeLeft = true;
					System::SetTimer(this, n"BackToMid", 8.f, false);
				}
			}
		}*/
	}

	UFUNCTION()
	void BackToMid()
	{
		TimeSpentNotSpottingPlayers = 0.f;
		bLedgeLeft = false;
	}

	UFUNCTION()
	void AllowPlayerSpotting()
	{
		bScanSpotPlayers = true;
	}

	UFUNCTION()
	void StartScanning()
	{
		bScanSpotPlayers = true;
		bScanning = true;
	}

	UFUNCTION()
	void StopScanning()
	{
		bScanSpotPlayers = false;
		bScanning = false;
	}

	UFUNCTION()
	void StartLedgeTracking()
	{
		TimeSpentNotSpottingPlayers = 0.f;
		bLedgeTracking = true;
	}
}