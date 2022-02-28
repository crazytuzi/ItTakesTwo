import Cake.Environment.GPUSimulations.PaperPainting;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Painting.PaintingAreaActor;

class APaintingWaterGlassActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent , Attach = Root)
	UBoxComponent BoxTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APaperPainting PaintActor;
	
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	APaintingAreaActor PaintingAreaActor;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAkAudioEvent MaySplashEnter;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAkAudioEvent MaySplashLeave;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAkAudioEvent CodySplashEnter;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAkAudioEvent CodySplashLeave;

	UPROPERTY()
	UNiagaraSystem WaterEffect;

	TPerPlayer<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnOverlap");
		BoxTrigger.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION()
	void TriggeredOnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player  = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			Players[Player] = Player;

			if(PaintActor != nullptr)
				PaintActor.ClearPlayerPaint(Player);
			
			if (Player.IsMay())
				PaintingAreaActor.StopMayTimeLike();
			else
				PaintingAreaActor.StopCodyTimeLike();

			if(Player.IsCody())
				Player.PlayerHazeAkComp.HazePostEvent(CodySplashEnter);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MaySplashEnter);

			if(WaterEffect != nullptr && Player.IsAnyCapabilityActive(n"GroundPoundFall"))
				Niagara::SpawnSystemAtLocation(WaterEffect, Player.ActorLocation);
		}
	}

	UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player  = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player != nullptr)
		{
			Players[Player] = nullptr;

			if(Player.IsCody())
				Player.PlayerHazeAkComp.HazePostEvent(CodySplashLeave);
			else
				Player.PlayerHazeAkComp.HazePostEvent(MaySplashLeave);

			if(WaterEffect != nullptr && Player.IsAnyCapabilityActive(n"GroundPoundFall"))
				Niagara::SpawnSystemAtLocation(WaterEffect, Player.ActorLocation);
		}
    }
}