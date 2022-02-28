import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnLandedOnPlatform(AHazePlayerCharacter Player);
event void FOnLeftPlatform(AHazePlayerCharacter Player);

class AClawMachineButton : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;
    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent ButtonMesh;
 	UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent ButtonMeshTrigger;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ButtonPushAudioEvent;

	UPROPERTY()
	FOnLandedOnPlatform OnLandedOnPlatform;
	UPROPERTY()
	FOnLeftPlatform OnLeftPlatform;
	
	FHazeAcceleratedFloat AcceleratedFloat;
	UPROPERTY()
	float PushDownValue = -25;
	float TargetValue;

	UPROPERTY()
	bool bOnlyTriggerForFirstPlayer = false;

	float AmountOfPlayersOnButton = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		//FActorImpactedByPlayerDelegate ImpactDelegate;
		//ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		//BindOnDownImpactedByPlayer(this, ImpactDelegate);

		//FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		//NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		//BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		ButtonMeshTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		ButtonMeshTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlapp");

    }


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(AmountOfPlayersOnButton > 0)
		{
			TargetValue = PushDownValue;
			AcceleratedFloat.SpringTo(TargetValue, 300.f, 0.4f, DeltaTime);
			ButtonMesh.SetRelativeLocation(FVector(0, 0, AcceleratedFloat.Value));
		}
		else
		{
			TargetValue = 0;
			AcceleratedFloat.SpringTo(TargetValue, 100.f, 0.5f, DeltaTime);
			ButtonMesh.SetRelativeLocation(FVector(0, 0, AcceleratedFloat.Value));
		}
	}


	UFUNCTION()
	void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
	UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
			{
				NetLandOnPlatform(Game::GetCody());
			}
		}
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
			{
				NetLandOnPlatform(Game::GetMay());
			}
		}
	}
	UFUNCTION(NetFunction)
	void NetLandOnPlatform(AHazePlayerCharacter Player)
	{	
		AmountOfPlayersOnButton ++;
		UHazeAkComponent::HazePostEventFireForget(ButtonPushAudioEvent, this.GetActorTransform());

		if(!bOnlyTriggerForFirstPlayer)
		{
			OnLandedOnPlatform.Broadcast(Player);
		}
		else
		{
			if(AmountOfPlayersOnButton == 1)
				OnLandedOnPlatform.Broadcast(Player);
		}

	}


	UFUNCTION(NotBlueprintCallable)
    void OnComponentEndOverlapp(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if(OtherActor == Game::GetCody())
		{
			if(Game::GetCody().HasControl())
			{
				NetLeavePlatform(Game::GetCody());
			}
		}
		if(OtherActor == Game::GetMay())
		{
			if(Game::GetMay().HasControl())
			{
				NetLeavePlatform(Game::GetMay());
			}
		}
    }
	UFUNCTION(NetFunction)
	void NetLeavePlatform(AHazePlayerCharacter Player)
	{
		AmountOfPlayersOnButton --;
		OnLeftPlatform.Broadcast(Player);
	}
}