import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.PlayerButtonMashIntoTomatoCapability;
import Cake.Environment.Breakable;
import Cake.Environment.BreakableStatics;
import Cake.Environment.BreakableComponent;

class AJoyPotActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBodySoil;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBodySign;
	UPROPERTY(DefaultComponent)
	USceneComponent PotExplosionLocation;

	UPROPERTY()
	ABreakableActor BreakAblePot;

	UPlayerButtonMashIntoTomatoComponent TomatoComponent;
	
	bool bActive = false;
	float ButtonMashProcent = 0;


	UPROPERTY()
	UNiagaraSystem PotExplosionEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BreakAblePot.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive)
			return;

		ButtonMashProcent =	TomatoComponent.ButtonMashCurrent/100;
		//Print("ButtonMashProcent  " + ButtonMashProcent);
	}

	UFUNCTION()
	void ExplodePot()
	{
		UBreakableComponent BreakableComp = UBreakableComponent::Get(BreakAblePot);
		if(BreakableComp != nullptr)
		{
			BreakAblePot.SetActorHiddenInGame(false);
			SetActorHiddenInGame(true);
			FBreakableHitData HitData;
			//HitData.DirectionalForce = -GetActorUpVector() * 10000.f;
			//HitData.ScatterForce = 3000.f;
			BreakBreakableActor(Cast<AHazeActor>(BreakAblePot), HitData);
		}

		Niagara::SpawnSystemAtLocation(PotExplosionEffect, PotExplosionLocation.GetWorldLocation(), PotExplosionLocation.GetWorldRotation(), bAutoDestroy=true);
		DestroyActor();
	}

	UFUNCTION()
	void SwapMeshes()
	{
		SetActorHiddenInGame(true);
		BreakAblePot.SetActorHiddenInGame(false);
	}
	UFUNCTION()
	void ManuallyDestroyPot()
	{
		DestroyActor();
		BreakAblePot.DestroyActor();
	}

	UFUNCTION()
	void ActivatePotActor()
	{	
		bActive = true;
		//UPlayerButtonMashIntoTomatoComponent Comp = Cast<UPlayerButtonMashIntoTomatoComponent>(Game::GetCody().GetComponentByClass(UPlayerButtonMashIntoTomatoComponent::StaticClass()));
		//TomatoComponent = Comp;
		//TomatoComponent.OnTomatoButtonMashSuccess.AddUFunction(this, n"ButtonMashComplete");
	}
}

