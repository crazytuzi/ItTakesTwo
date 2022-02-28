import Peanuts.Triggers.PlayerTrigger;

class ASpaWaterVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent TriggerBox;

	UPROPERTY(DefaultComponent)	
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 30000.f;

	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent WaterSurfaceLocationHeight;

	UPROPERTY()
	UNiagaraSystem EnterEffect;
	UPROPERTY()
	UNiagaraSystem ExitEffect;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent MayLoopingWaterVFX;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent CodyLoopingWaterVFX;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayEnterWaterEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyEnterWaterEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayLeaveWaterEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyLeaveWaterEvent;

	bool bMayInsideWater;
	bool bCodyInsideWater;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerBox.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlapSafe");
		TriggerBox.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlapSafe");
		CodyLoopingWaterVFX.SetWorldScale3D(FVector(1,1,1));
		MayLoopingWaterVFX.SetWorldScale3D(FVector(1,1,1));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMayInsideWater)
		{
			MayLoopingWaterVFX.SetWorldLocation(FVector(Game::GetMay().GetActorLocation().X, Game::GetMay().GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z));
		}
		if(bCodyInsideWater)
		{
			CodyLoopingWaterVFX.SetWorldLocation(FVector(Game::GetCody().GetActorLocation().X, Game::GetCody().GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z));
		}
	}

	UFUNCTION()
	void OnComponentBeginOverlapSafe(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
				NetMayEnterWater(Game::GetMay());
		}
		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
				NetCodyEnterWater(Game::GetCody());
		}
	}

	UFUNCTION()
	void OnComponentEndOverlapSafe(
		UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
				NetMayExitWater(Game::GetMay());
		}
		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
				NetCodyExitWater(Game::GetCody());
		}
	}

	UFUNCTION(NetFunction)
	void NetMayEnterWater(AHazePlayerCharacter Player)
	{
		Niagara::SpawnSystemAtLocation(EnterEffect, FVector(Player.GetActorLocation().X, Player.GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z), Player.GetActorRotation());
		bMayInsideWater = true;
		MayLoopingWaterVFX.Activate();
		Player.PlayerHazeAkComp.HazePostEvent(MayEnterWaterEvent);
	}
	UFUNCTION(NetFunction)
	void NetMayExitWater(AHazePlayerCharacter Player)
	{
		Niagara::SpawnSystemAtLocation(ExitEffect, FVector(Player.GetActorLocation().X, Player.GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z), Player.GetActorRotation());
		bMayInsideWater = false;
		MayLoopingWaterVFX.Deactivate();
		Player.PlayerHazeAkComp.HazePostEvent(MayLeaveWaterEvent);
	}

	UFUNCTION(NetFunction)
	void NetCodyEnterWater(AHazePlayerCharacter Player)
	{
		Niagara::SpawnSystemAtLocation(EnterEffect, FVector(Player.GetActorLocation().X, Player.GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z), Player.GetActorRotation());
		bCodyInsideWater = true;
		CodyLoopingWaterVFX.Activate();
		Player.PlayerHazeAkComp.HazePostEvent(CodyEnterWaterEvent);
	}
	UFUNCTION(NetFunction)
	void NetCodyExitWater(AHazePlayerCharacter Player)
	{
		Niagara::SpawnSystemAtLocation(ExitEffect, FVector(Player.GetActorLocation().X, Player.GetActorLocation().Y, WaterSurfaceLocationHeight.GetWorldLocation().Z), Player.GetActorRotation());
		bCodyInsideWater = false;
		CodyLoopingWaterVFX.Deactivate();
		Player.PlayerHazeAkComp.HazePostEvent(CodyLeaveWaterEvent);
	}
}

