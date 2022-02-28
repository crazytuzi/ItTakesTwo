import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Peanuts.Triggers.PlayerTrigger;

UCLASS(Abstract)
class AWorm : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	USceneComponent SceneEffectLocation;
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	UPROPERTY(DefaultComponent)
	UVineImpactComponent VineImpactComp;
	default VineImpactComp.bUseWidget = false;
	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	bool bCanOnlyExitOnce = false;
	bool bDoOnce = false;
	
	UPROPERTY()
	UNiagaraSystem Exit;
	UPROPERTY()
	UNiagaraSystem Enter;

	FVector EffectLocation;
	FRotator EffectRotation;

	UPROPERTY()
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	UAnimSequence ExitAnimation;
	UPROPERTY()
	UAnimSequence EnterAnimation;
	UPROPERTY()
	UAnimSequence OutsideMHAnimation;
	UPROPERTY()
	UAnimSequence InsideMHAnimation;

	UPROPERTY()
	bool StartOut = true;
	UPROPERTY()
	bool AutomaticallyGoOutsideAfterReatract = true;
	bool IsOutside;
	float TimeToComeOutsideAgain = 5.f;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineWhipped");
		VineImpactComp.OnVineWhipped.AddUFunction(this, n"VineWhipped");
		
		WaterHoseComp.OnHitWithWater.AddUFunction(this, n"Watered");
		if(PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerNearWorm");
		VineImpactComp.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Worm17"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		VineImpactComp.AddLocalOffset(FVector(0, 0, 30));

		EffectLocation = SceneEffectLocation.GetWorldLocation();
		EffectRotation = SceneEffectLocation.GetWorldRotation();

		if(StartOut == true)
		{
			IsOutside = true;
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = OutsideMHAnimation, bLoop = true);
		}
		else
		{
			IsOutside = false;
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = InsideMHAnimation, bLoop = true);
		}
	}

	UFUNCTION()
	void StartExit()
	{
		if(bDoOnce)
			return;
		if(bCanOnlyExitOnce)
			bDoOnce = true;

		IsOutside = false;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"AnimationStopped");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = ExitAnimation, bLoop = false);
		Niagara::SpawnSystemAtLocation(Exit, EffectLocation, EffectRotation, bAutoDestroy=true);
	}
	UFUNCTION()
	void StartEnter()
	{
		IsOutside = true;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"AnimationStopped");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = EnterAnimation, bLoop = false);
		Niagara::SpawnSystemAtLocation(Enter, EffectLocation, EffectRotation, bAutoDestroy=true);
	}

	UFUNCTION(NotBlueprintCallable)
	void AnimationStopped()
	{
		if(IsOutside == true)
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = OutsideMHAnimation, bLoop = true);

			if(PlayerTrigger != nullptr)
			{
				TArray<AActor> Actors;
				PlayerTrigger.GetOverlappingActors(Actors);

				for (auto Actor : Actors)
				{
					auto Player = Cast<AHazePlayerCharacter>(Actor);
					if(Player != nullptr)
					{
						StartExit();
						if(AutomaticallyGoOutsideAfterReatract)
							System::SetTimer(this, n"StartEnter", TimeToComeOutsideAgain, false);
					}
					
				}
			}
		}
		else
		{
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOut;
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = InsideMHAnimation, bLoop = true);
		}
	}

	/////Networked by player trigger
	UFUNCTION(NotBlueprintCallable)
	void OnPlayerNearWorm(AHazePlayerCharacter Player)
	{
		if(IsOutside == false)
			return;

		StartExit();
		if(AutomaticallyGoOutsideAfterReatract)
			System::SetTimer(this, n"StartEnter", TimeToComeOutsideAgain, false);
	}


	//////OnVineWhipped is Networked
	UFUNCTION(NotBlueprintCallable)
	void VineWhipped()
	{
		if(IsOutside == false)
			return;
		
		StartExit();

		if(AutomaticallyGoOutsideAfterReatract)
			System::SetTimer(this, n"StartEnter", TimeToComeOutsideAgain, false);
	}

	//////OnWaterd is networked
	UFUNCTION(NotBlueprintCallable)
	void Watered()
	{
		if(IsOutside == false)
			return;

		StartExit();

		if(AutomaticallyGoOutsideAfterReatract)
			System::SetTimer(this, n"StartEnter", TimeToComeOutsideAgain, false);
	}
}