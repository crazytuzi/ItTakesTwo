import Vino.Pickups.PickupActor;

UCLASS(hidecategories="Rendering Collision Replication Input")
class ALaserToy : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = PickupRoot)	
	USceneComponent LaserStartPosition;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent LaserBeam;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent LaserBeamImpact;

	UPROPERTY()
	TSubclassOf<UHazeCapability> LaserAimPlayerCapability;

	bool bLaserActive = false;
	FVector ImpactLocation;
	float MainTraceDefaultLength = 25000.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bLaserActive)
		{
			FVector End = LaserStartPosition.GetWorldLocation() + LaserStartPosition.GetForwardVector() * MainTraceDefaultLength;
			TArray<AActor> ActorsToIgnore;
			ActorsToIgnore.AddUnique(this);
			TArray<FHitResult> HitResult;
			//Trace::(Start, End, 30.f, ETraceTypeQuery::Camera, false, ActorsToIgnore, HitResult, -1.f);
			System::SphereTraceMultiByProfile(LaserStartPosition.GetWorldLocation(), End, 5.f, n"PlayerCharacter", false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);

			for (FHitResult Hit : HitResult)
			{	
				if(Hit.bBlockingHit)
				{	
					ImpactLocation = Hit.ImpactPoint;
				}
				if(Hit.Actor == Game::GetCody())
				{
					PrintToScreen("CodyIsHit");
				}
				if(Hit.Actor == Game::GetMay())
				{
					PrintToScreen("MaysIsHit");
				}
			}

			LaserBeam.SetNiagaraVariableVec3("User.BeamEnd", ImpactLocation);
			LaserBeam.SetNiagaraVariableVec3("User.BeamStart", LaserStartPosition.GetWorldLocation());
			LaserBeamImpact.SetWorldLocation(ImpactLocation);
		}
	}

	UFUNCTION()
	void ActivateLaser()
	{
		bLaserActive = true;
		LaserBeam.Activate();
		LaserBeamImpact.Activate();
	}
	UFUNCTION()
	void DeactivateLaser()
	{
		bLaserActive = false;
		LaserBeam.Deactivate();
		LaserBeamImpact.Deactivate();
	}


	UFUNCTION(NotBlueprintCallable)
	protected void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPickedUpDelegate(Player, PickupActor);
		Player.AddCapability(LaserAimPlayerCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPutDownDelegate(AHazePlayerCharacter Player, APickupActor PickupActor)
	{
		Super::OnPutDownDelegate(Player, PickupActor);
		Player.RemoveCapability(LaserAimPlayerCapability);
	}
}