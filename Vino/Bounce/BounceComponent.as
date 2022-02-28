import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

event void PlayerLandedOnActor();
event void PlayerLeftActor();
event void PlayerOnComponent();
event void NoPlayerOnComponent();

class UBounceComponent : USceneComponent
{
	// The component we are bouncing
	USceneComponent CompToBounce;

	// If only one specific component should trigger an impact and bounce the actor
	UPROPERTY()
	bool bSpecificImpactComponent = false;

	// Name of the component that can trigger an impact
	UPROPERTY(Meta = (EditCondition = "bSpecificImpactComponent"))
	FString ComponentToBeImpacted;

	// Use array if multiple components can trigger an impact
	UPROPERTY(Meta = (EditCondition = "bSpecificImpactComponent"))
	TArray<FString> ComponentsToBeImpacted;

	UPROPERTY()
	float LowerBound = 0.f;

	UPROPERTY()
	float UpperBound = 6000.f;

	UPROPERTY()
	float LowerBounciness = .4f;

	UPROPERTY()
	float UpperBounciness = .4f;

	UPROPERTY()
	float Friction = 0.f;

	UPROPERTY()
	float AccelerationForce = 400.f;

	UPROPERTY()
	float ImpactImpulseForce = 400.f;

	UPROPERTY()
	bool bShouldSpringUpwards = false;

	UPROPERTY(Meta = (EditCondition = "bShouldSpringUpwards"))
	float SpringValue = 10.f;

	UPROPERTY()
	float GroundPoundForce = 800.f;

	UPROPERTY()
	bool bMoveComponentInWorldSpace = false;

	UPROPERTY()
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY()
	PlayerLandedOnActor AudioLandedOnActor;
	UPROPERTY()
	PlayerLeftActor AudioLeftActor;
	UPROPERTY()
	PlayerOnComponent AudioPlayerOnComponent;
	UPROPERTY()
	NoPlayerOnComponent AudioNoPlayerOnComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerLandedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerLeftAudioEvent;

	bool bComponentEnabled = true;
	bool bPlayerOnComponent = false;

	FVector InitialWorldLocation;
	float AppliedPhysValue = MAX_flt;
	
	FHazeConstrainedPhysicsValue PhysValue;

	TArray<AHazePlayerCharacter> PlayersOnActor;
	int NumPlayersOnPlatform = 0;

	// Used to track the primitives attached to the owner
	TArray<UPrimitiveComponent> PrimArray;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (GroundPoundComp == nullptr)
		{
			GroundPoundComp = UGroundPoundedCallbackComponent::GetOrCreate(Owner);
		}
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnButtonGroundPounded");
		PhysValue.LowerBound = LowerBound;
		PhysValue.UpperBound = UpperBound;
		PhysValue.LowerBounciness = LowerBounciness;
		PhysValue.UpperBounciness = UpperBounciness;
		PhysValue.Friction = Friction;

		// Need to cast Owner to AHazeActor to bind the Impact Delegates
		AHazeActor Parent = Cast<AHazeActor>(Owner);
		
		CompToBounce = GetAttachParent();

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(Parent, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(Parent, NoImpactDelegate);

		UActorImpactedCallbackComponent::Get(Parent).bCanBeActivedLocallyOnTheRemote = true;
		
		GatherPrimitives();

		if (bMoveComponentInWorldSpace)
			InitialWorldLocation = CompToBounce.WorldLocation;
	}

	void GatherPrimitives()
	{
		TArray<UActorComponent> TempArray;
		Owner.GetAllComponents(UPrimitiveComponent::StaticClass(), TempArray);
		// Gather all relevant primitives. Only saving the primitives that can trigger a bounce
		if (bSpecificImpactComponent)
		{
			for(auto Component : TempArray)
			{	
				if (Component.Name == ComponentToBeImpacted || ComponentsToBeImpacted.Contains(Component.Name))
					PrimArray.Add(Cast<UPrimitiveComponent>(Component));	
			}
		} 
		// If all primitives can trigger a bounce, save all of them
		else
		{
			for(auto Component : TempArray)
			{
				PrimArray.Add(Cast<UPrimitiveComponent>(Component));
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if (!bComponentEnabled)
		{
			SetComponentTickEnabled(false);
			return;
		}

		CheckIfPlayerLeftActor();
		PhysValue.AddAcceleration(AccelerationForce * NumPlayersOnPlatform);
		
		if (bShouldSpringUpwards)
			PhysValue.SpringTowards(0.f, SpringValue);
		
		PhysValue.Update(DeltaTime); 

		if (!FMath::IsNearlyEqual(PhysValue.Value, AppliedPhysValue, 0.1f))
		{
			if (!bMoveComponentInWorldSpace)
				CompToBounce.SetRelativeLocation(FVector::UpVector * -PhysValue.Value);
			else 
				CompToBounce.SetWorldLocation(InitialWorldLocation + FVector::UpVector * -PhysValue.Value);
			AppliedPhysValue = PhysValue.Value;
		}

		// Stop ticking if the PhysValue has settled
		if (PhysValue.CanSleep(SettledTargetValue = 0.f) && NumPlayersOnPlatform == 0)
			SetComponentTickEnabled(false);
	}

	// Check if we allow a player to trigger "leave bounce"
	void CheckIfPlayerLeftActor()
	{
		for (int i = PlayersOnActor.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = PlayersOnActor[i];

			// if the player became airborne it's no longer on the actor
			if (Player.MovementComponent.BecameAirborne())
			{
				LeaveBounceableActor(Player);
				continue;
			}
			
			if (CheckPrimitives(Player, PrimArray))
			{
				LeaveBounceableActor(Player);
			}
		}
	}

	bool CheckPrimitives(AHazePlayerCharacter Player, TArray<UPrimitiveComponent> NewPrimArray)
	{
		for (UPrimitiveComponent Prim : NewPrimArray)
		{
			FVector OutVector;
			if (Prim.GetClosestPointOnCollision(Player.ActorLocation, OutVector) <= -1.f)
				continue;
			FVector Delta = OutVector - Player.ActorLocation;
			Delta = Delta.ConstrainToPlane(Player.ActorUpVector);
			
			if (Delta.Size() < Player.MovementComponent.CollisionShape.Extent.X)
				return false;
		}
		return true;
	}

    UFUNCTION(NotBlueprintCallable)
    void OnButtonGroundPounded(AHazePlayerCharacter Player)
    {
		SetComponentTickEnabled(true);
		PhysValue.AddImpulse(GroundPoundForce);
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		if (!bComponentEnabled)
			return;
		
		if (PlayersOnActor.Contains(Player))
			return;

		if (bSpecificImpactComponent)
		{
			if (Hit.Component.Name != ComponentToBeImpacted && !ComponentsToBeImpacted.Contains(Hit.Component.Name))
				return;
		}

		PhysValue.AddImpulse(ImpactImpulseForce);
		PlayersOnActor.AddUnique(Player);
		UpdateNumOfPlayers();
		SetComponentTickEnabled(true);

		Player.PlayerHazeAkComp.HazePostEvent(PlayerLandedAudioEvent);
		AudioLandedOnActor.Broadcast();
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		if (!bComponentEnabled)
			return;

		if (Player.MovementComponent.IsAirborne())
		{
			LeaveBounceableActor(Player);
			return;
		}
	}

	void LeaveBounceableActor(AHazePlayerCharacter Player)
	{
		PlayersOnActor.Remove(Player);
		UpdateNumOfPlayers();
		Player.PlayerHazeAkComp.HazePostEvent(PlayerLeftAudioEvent);
		AudioLeftActor.Broadcast();
	}

	UFUNCTION()
	void AddBounceImpulse(float ImpulseForce)
	{
		SetComponentTickEnabled(true);
		PhysValue.AddImpulse(ImpulseForce);
	}

	void UpdateNumOfPlayers()
	{
		NumPlayersOnPlatform = PlayersOnActor.Num();

		if(!bPlayerOnComponent)
		{
			if(NumPlayersOnPlatform >= 1)
			{
				AudioPlayerOnComponent.Broadcast();
				bPlayerOnComponent = true;
			}
		}

		if(bPlayerOnComponent)
		{
			if(NumPlayersOnPlatform == 0)
			{
				AudioNoPlayerOnComponent.Broadcast();
				bPlayerOnComponent = false;
			}
		}
	}

	void SetBounceComponentEnabled(bool bEnabled)
	{
		bComponentEnabled = bEnabled;
		PlayersOnActor.Empty();
		if (bEnabled)
			SetComponentTickEnabled(true);
	}
}
