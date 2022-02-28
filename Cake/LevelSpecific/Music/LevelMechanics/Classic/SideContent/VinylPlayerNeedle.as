import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.VinylPlayer;

class AVinylPlayerNeedle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent RotatingRootNeedle;
	UPROPERTY(DefaultComponent, Attach = RotatingRootNeedle)	
	UStaticMeshComponent RotatingMeshNeedle;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	AVinylPlayer VinylPlayer;
	UPROPERTY()
	APlayerTrigger ValidAreaOnNeedle;

	FHazeAcceleratedFloat AcceleratedFloatNeedle;

	bool bCodyValidArea = false;
	bool bMayValidArea = false;
	bool bCodyStandingOnNeedle = false;
	bool bMayStandingOnNeedle = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"AddPlayerNeedle");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);
		FActorNoLongerImpactingDelegate OnPlayerJumped;
        OnPlayerJumped.BindUFunction(this, n"RemovePlayerNeedle");
        BindOnDownImpactEnded(this, OnPlayerJumped);

		ValidAreaOnNeedle.OnPlayerEnter.AddUFunction(this, n"AddPlayerValidArea");
		ValidAreaOnNeedle.OnPlayerLeave.AddUFunction(this, n"RemovePlayerValidArea");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) 
	{
	//	PrintToScreen("bCodyStandingOnNeedle "+ bCodyStandingOnNeedle);
	//	PrintToScreen("bMayStandingOnNeedle "+ bMayStandingOnNeedle);
	//	PrintToScreen("bCodyValidArea "+ bCodyValidArea);
	//	PrintToScreen("bMayValidArea "+ bMayValidArea);

		if(bCodyStandingOnNeedle == true && bCodyValidArea or bMayStandingOnNeedle == true && bMayValidArea)
		{
			AcceleratedFloatNeedle.SpringTo(-0.5, 300, 0.8f, DeltaSeconds);
			RotatingMeshNeedle.SetRelativeRotation(FRotator(AcceleratedFloatNeedle.Value,0,0));
		}
		else
		{
			AcceleratedFloatNeedle.SpringTo(0, 300, 0.95f, DeltaSeconds);
			RotatingMeshNeedle.SetRelativeRotation(FRotator(AcceleratedFloatNeedle.Value,0,0));
		}
	}

	UFUNCTION()
	void AddPlayerValidArea(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody())
		{
			bCodyValidArea = true;
			if(bCodyStandingOnNeedle)
			{
				FHitResult Empty;
				AddPlayerNeedle(Game::GetCody(), Empty);
			}
		}
		if(Player == Game::GetMay())
		{
			bMayValidArea = true;
			if(bMayStandingOnNeedle)
			{
				FHitResult Empty;
				AddPlayerNeedle(Game::GetMay(), Empty);
			}
		}
	}
	UFUNCTION()
	void RemovePlayerValidArea(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody())
		{
			bCodyValidArea = false;
			if(bCodyStandingOnNeedle == true)
			{
				VinylPlayer.RemovePlayerNeedle();
			}
		}
		if(Player == Game::GetMay())
		{
			bMayValidArea = false;
			if(bMayStandingOnNeedle == true)
			{
				VinylPlayer.RemovePlayerNeedle();
			}
		}
	}

	UFUNCTION()
	void AddPlayerNeedle(AHazePlayerCharacter Player, FHitResult HitResult)
	{
		if(Player == Game::GetCody())
		{
			bCodyStandingOnNeedle = true;
			if(bCodyValidArea)
			{
				VinylPlayer.AddPlayerNeedle(Game::GetCody());
			}
		}
		if(Player == Game::GetMay())
		{
			bMayStandingOnNeedle = true;
			if(bMayValidArea)
			{
				VinylPlayer.AddPlayerNeedle(Game::GetMay());
			}
		}
	}
	UFUNCTION()
	void RemovePlayerNeedle(AHazeActor Actor)
	{
		if(Actor == Game::GetCody())
		{
			bCodyStandingOnNeedle = false;
			if(bCodyValidArea)
			{
				VinylPlayer.RemovePlayerNeedle();
			}
		}
		if(Actor == Game::GetMay())
		{
			bMayStandingOnNeedle = false;
			if(bMayValidArea)
			{
				VinylPlayer.RemovePlayerNeedle();
			}
		}
	}
}

