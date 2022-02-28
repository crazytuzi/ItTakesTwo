import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.Cake.CourtyardCakeCharacter;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
import Peanuts.Foghorn.FoghornStatics;

class ACourtyardCake : APaintablePlane
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CakeMesh;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle1;
	UPROPERTY(DefaultComponent, Attach = Candle1)
	UNiagaraComponent Flame1;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle2;
	UPROPERTY(DefaultComponent, Attach = Candle2)
	UNiagaraComponent Flame2;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle3;
	UPROPERTY(DefaultComponent, Attach = Candle3)
	UNiagaraComponent Flame3;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle4;
	UPROPERTY(DefaultComponent, Attach = Candle4)
	UNiagaraComponent Flame4;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle5;
	UPROPERTY(DefaultComponent, Attach = Candle5)
	UNiagaraComponent Flame5;

	UPROPERTY(DefaultComponent, Attach = CakeMesh)
	UStaticMeshComponent Candle6;
	UPROPERTY(DefaultComponent, Attach = Candle6)
	UNiagaraComponent Flame6;

	TArray<FCourtyardCakeCandlePair> CandlePairs;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HappyCrowdAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SadCrowdAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SplashAudioEvent;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundCallbackComp;

	UPROPERTY()
	UCastleCourtyardVOBank VOBank;
	TPerPlayer<bool> bBarkPlayed;

	bool bDestroyed = false;

	bool bHasPlayedSound = false;

	UPROPERTY()
	UNiagaraSystem CakeExplosionEffect;

	UPROPERTY()
	UTexture2D SplashTexture;

	UPROPERTY()
	TArray<ACourtyardCakeCharacter> CakeCharacters;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		GroundPoundCallbackComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
		auto mat = CakeMesh.CreateDynamicMaterialInstance(0);
		mat.SetVectorParameterValue(n"WitherPlaneTransform", WitherPlaneTransform);
		mat.SetTextureParameterValue(n"SimulationTexture", SimulationBuffer.ActiveTarget);

		// I hate myself enough, don't hate me even more
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle1, Flame1));
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle2, Flame2));
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle3, Flame3));
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle4, Flame4));
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle5, Flame5));
		CandlePairs.Add(FCourtyardCakeCandlePair(Candle6, Flame6));

		HazeAkComp.HazePostEvent(HappyCrowdAudioEvent);
	}

	float Delay = 0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		Delay -= DeltaTime;
		if(Delay <= 0)
		{
			Delay = 1.0f / 30.0f; // Limit draw-rate to 30 fps

			for(auto Player : Game::GetPlayers())
			{
				if(Player.GetActorVelocity().SizeSquared() <= 0)
					continue;
				LerpAndDrawTexture(Player.GetActorLocation(), 70, FLinearColor(1,1,1,1), FLinearColor(1,1,1,1), false, nullptr, true);
			}

			for (int Index = CandlePairs.Num() - 1; Index >= 0; Index--)
			{
				FVector CandleLocation = CandlePairs[Index].Candle.WorldLocation;
				
				FWitherSimulationArrayQueryData Data = QueryData(CandleLocation);
				
				if (Data.Color.R > 0.5f)
				{
					CandlePairs[Index].Flame.DestroyComponent(this);
					CandlePairs[Index].Candle.SimulatePhysics = true;
					CandlePairs[Index].Candle.SetPhysicsLinearVelocity(CandlePairs[Index].Candle.ForwardVector * 160.f);

					CandlePairs.RemoveAt(Index);
				}
			}
		}

		// FWitherSimulationArrayQueryData Data = QueryData(FVector::ZeroVector);
		// Data.
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		LerpAndDrawTexture(Player.GetActorLocation() + FVector(200, 0, 0), 1000, FLinearColor(1, 1, 1, 1), FLinearColor(2, 2, 2, 2), false, SplashTexture, true);
		SwapAndDraw(UpdateSimulationMaterialDynamic, SimulationBuffer);

		if (!bHasPlayedSound)
		{
			HazeAkComp.HazePostEvent(SadCrowdAudioEvent);
			bHasPlayedSound = true;
		}
		

		if (CakeExplosionEffect != nullptr)
			Niagara::SpawnSystemAtLocation(CakeExplosionEffect, Player.ActorLocation);
			Player.PlayerHazeAkComp.HazePostEvent(SplashAudioEvent);

		if (bDestroyed)
			return;
		bDestroyed = true;
		
		for (ACourtyardCakeCharacter Character : CakeCharacters)
		{
			Character.CakeDestroyed();
		}

		if (bBarkPlayed[Player])
			return;
		bBarkPlayed[Player] = true;
		FName EventName = Player.IsMay() ? n"FoghornDBPlayroomCastleCakeSmashMay" : n"FoghornDBPlayroomCastleCakeSmashCody";
		PlayFoghornVOBankEvent(VOBank, EventName);
	}
}

struct FCourtyardCakeCandlePair
{
	UStaticMeshComponent Candle;
	UNiagaraComponent Flame;

	FCourtyardCakeCandlePair(UStaticMeshComponent InCandle, UNiagaraComponent InFlame)
	{
		Candle = InCandle;
		Flame = InFlame;
	}
}