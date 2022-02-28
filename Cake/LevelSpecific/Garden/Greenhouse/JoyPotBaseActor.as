import Peanuts.Triggers.PlayerTrigger;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.Environment.Breakable;
import Cake.Environment.BreakableStatics;

event void FOnPlateDestroyed();
class AJoyPotBaseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBodyBroken1;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBodyBroken2;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitWithoutCrackingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitWithSmallCrackAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitWithLargeCrackAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PotBaseDestroyAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	FOnPlateDestroyed OnPlateDestroyed;

	UPROPERTY()
	APlayerTrigger PlayerDeathTrigger;

	FHazeAcceleratedFloat AcceleratedFloat;

	UPROPERTY()
	ADecalActor BlobDecal;
	UPROPERTY()
	ABreakableActor BreakAblePotBase;
	
	bool bActive = false;
	bool bCanPlayerDie = false;
	bool bFadeAway = false;

	UPROPERTY()
	int TimesHit = 0;
	UPROPERTY()
	int TimesHitUntilFirstCrack = 2;
	UPROPERTY()
	int TimesHitMax = 10;
	UPROPERTY()
	bool bFallAnimationOne;
	UPROPERTY()
	bool bFallAnimationTwo;
	UPROPERTY()
	bool bFallAnimationThree;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerDeathTrigger.OnPlayerEnter.AddUFunction(this, n"OnComponentBeginOverlap");
		PlayerDeathTrigger.OnPlayerLeave.AddUFunction(this, n"OnComponentEndOverlap");
		PlayerDeathTrigger.AttachToComponent(MeshBody, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		PlayerDeathTrigger.AddActorLocalOffset(FVector(0, 0, 35));
		BlobDecal.SetActorHiddenInGame(true);
		MeshBodyBroken1.SetHiddenInGame(true);
		MeshBodyBroken2.SetHiddenInGame(true);
		BreakAblePotBase.SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFadeAway)
		{
			if(AcceleratedFloat.Value >= 0.3)
				AcceleratedFloat.SpringTo(0, 1, 1, DeltaSeconds * 0.35f);
			else
				AcceleratedFloat.SpringTo(-0.1, 10, 1, DeltaSeconds * 0.35f);

			BlobDecal.SetActorScale3D(FVector(0.2, AcceleratedFloat.Value, AcceleratedFloat.Value));

			PrintToScreen("AcceleratedFloat " + AcceleratedFloat.Value);
			if(AcceleratedFloat.Value <= 0)
			{
				BlobDecal.SetActorHiddenInGame(true);
				bFadeAway = false;
			}
		}

		if(!bCanPlayerDie)
			return;

	//	PrintToScreen("AcceleratedFloat.Value " + AcceleratedFloat.Value);

		/*
		if(bFallAnimationOne)
		{
			if(AcceleratedFloat.Value <= 0.875)
				AcceleratedFloat.SpringTo(1.25, 5, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 0.875)
				AcceleratedFloat.SpringTo(3.25, 30, 1, DeltaSeconds);
		}
		if(bFallAnimationTwo)
		{
			if(AcceleratedFloat.Value <= 1.1)
				AcceleratedFloat.SpringTo(1.25, 5, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 1.1)
				AcceleratedFloat.SpringTo(3.25, 30, 1, DeltaSeconds);
		}
		if(bFallAnimationThree)
		{
			if(AcceleratedFloat.Value <= 1.1)
				AcceleratedFloat.SpringTo(1.25, 5.5, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 1.1)
				AcceleratedFloat.SpringTo(3.25, 30, 1, DeltaSeconds);
		}
		*/


		//Less real shadow but better for gameplay
		if(bFallAnimationOne)
		{
			if(AcceleratedFloat.Value <= 2)
				AcceleratedFloat.SpringTo(2.95, 7, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 2)
				AcceleratedFloat.SpringTo(3.25, 30, 1, DeltaSeconds * 0.5f);
		}
		if(bFallAnimationTwo)
		{
			if(AcceleratedFloat.Value <= 2)
				AcceleratedFloat.SpringTo(2.95, 4, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 2)
				AcceleratedFloat.SpringTo(3.25, 8, 1, DeltaSeconds * 0.5f);
		}
		if(bFallAnimationThree)
		{
			if(AcceleratedFloat.Value <= 2)
				AcceleratedFloat.SpringTo(2.95, 4, 1, DeltaSeconds * 0.35f);
			if(AcceleratedFloat.Value > 2)
				AcceleratedFloat.SpringTo(3.25, 15, 1, DeltaSeconds * 0.5f);
		}
		


		BlobDecal.SetActorScale3D(FVector(0.2, AcceleratedFloat.Value, AcceleratedFloat.Value));
	}

	UFUNCTION()
	void SetDeathVolume(bool LocalActive)
	{	
		BlobDecal.SetActorHiddenInGame(false);

		if(LocalActive)
			bCanPlayerDie = true;

		if(!LocalActive)
			bCanPlayerDie = false;
	}

	UFUNCTION()
	void SetBlobDecalHidden()
	{	
		bFadeAway = true;
	}

	UFUNCTION()
	void ImpactCrumble()
	{
		TimesHit ++;
		if(TimesHit >= TimesHitMax)
		{
			UBreakableComponent BreakableComp = UBreakableComponent::Get(BreakAblePotBase);
			if(BreakableComp != nullptr)
			{
				BreakAblePotBase.SetActorHiddenInGame(false);
				SetActorHiddenInGame(true);
				FBreakableHitData HitData;
				HitData.DirectionalForce = -GetActorUpVector() * 1000.f;
				HitData.ScatterForce = 2000.f;
				BreakBreakableActor(Cast<AHazeActor>(BreakAblePotBase), HitData);
			}

			//audio trigger for destroy pot base sound
			UHazeAkComponent::HazePostEventFireForget(PotBaseDestroyAudioEvent, this.GetActorTransform());

			OnPlateDestroyed.Broadcast();
			DestroyActor();
		}
		else
		{
			//Print("TimesHit  " + TimesHit, 3.f);
			if(TimesHitUntilFirstCrack == TimesHit)
			{
				MeshBody.SetHiddenInGame(true);
				MeshBodyBroken1.SetHiddenInGame(false);
				MeshBodyBroken2.SetHiddenInGame(true);
			}
			else if(TimesHit == TimesHitMax -1)
			{
				MeshBody.SetHiddenInGame(true);
				MeshBodyBroken1.SetHiddenInGame(true);
				MeshBodyBroken2.SetHiddenInGame(false);

				//audio trigger for hit with large crack sound
				HazeAkComp.HazePostEvent(HitWithLargeCrackAudioEvent);
			}

			if(TimesHit < TimesHitUntilFirstCrack)
			{
				//audio trigger for hit without cracking sound
				HazeAkComp.HazePostEvent(HitWithoutCrackingAudioEvent);

			}

			
			if((TimesHit >= TimesHitUntilFirstCrack) && (TimesHit < TimesHitMax -1))
			{
				//audio trigger for hit with small crack sound
				HazeAkComp.HazePostEvent(HitWithSmallCrackAudioEvent);
			}
				
		}
	}


	UFUNCTION()
	void OnComponentBeginOverlap(AHazePlayerCharacter Player)
	{
		if(!bCanPlayerDie)
			return;

		if(Player.HasControl())
		{
			Player.KillPlayer(DeathEffect);
		}
	}

	UFUNCTION()
	void OnComponentEndOverlap(AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{
			
		}
	}
}

