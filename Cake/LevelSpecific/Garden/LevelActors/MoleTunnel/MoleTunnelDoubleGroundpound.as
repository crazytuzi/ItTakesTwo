import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.FloorJumpCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Triggers.PlayerTrigger;

event void FOnGroundPoundSuccessful();

class AMoleTunnelDoubleGroundpound : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshVisual;
	UPROPERTY(DefaultComponent)
	USceneComponent GroundPoundLocationWidget;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UNiagaraComponent DirtSplash;
	UPROPERTY()
	APlayerTrigger CountAmountOfPlayers;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EnterAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeaveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SingleGroundPoundAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoubleGroundPoundAudioEvent;

	UPROPERTY(DefaultComponent)	
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 5000;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY()
	FOnGroundPoundSuccessful StartCutscene;
	bool MayHasRecentlyPounded;
	bool CodyHasRecentlyPounded;
	bool BothPlayersHasGroundPounded = false;
	float MayTimer = 0.f;
	float CodyTimer = 0.f;
	int DoubleGroundPoundAmount = 0;

	float GroundPoundBlendValue;
	float StandingOnBendValue;
	float GroundPoundBlendValueCollision;
	float StandingOnBendValueCollision;

	FHazeAcceleratedFloat AcceleratedFloatBend;
	FHazeAcceleratedFloat AcceleratedFloatCollisionOffset;
	bool bBendDownwards;
	int PlayerInt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundedz;
		GroundPoundedz.BindUFunction(this, n"WasGroundPounded");
		BindOnActorGroundPounded(this, GroundPoundedz);
		CountAmountOfPlayers.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterTrigger");
		CountAmountOfPlayers.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaveTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(!BothPlayersHasGroundPounded)
		{
			MayTimer -= DeltaTime;
			MayHasRecentlyPounded = MayTimer >= 0.f;
			CodyTimer -= DeltaTime;
			CodyHasRecentlyPounded = CodyTimer >= 0.f;
		}

		if(MayHasRecentlyPounded && CodyHasRecentlyPounded)
		{	
			if(HasControl())
			{
				NetIncreaseDoubleGroundPoundAmount();
			}															
		}

		AcceleratedFloatBend.SpringTo(GroundPoundBlendValue + StandingOnBendValue, 200, 1, DeltaTime);
		AcceleratedFloatCollisionOffset.SpringTo(GroundPoundBlendValueCollision + StandingOnBendValueCollision, 400, 1, DeltaTime);

		MeshVisual.SetScalarParameterValueOnMaterials(n"BlendValue", AcceleratedFloatBend.Value);
		Mesh.SetRelativeLocation(FVector(0,0, AcceleratedFloatCollisionOffset.Value));
	}

	UFUNCTION(NetFunction)
	void NetIncreaseDoubleGroundPoundAmount()
	{
		CodyTimer = 0.f;
		MayTimer = 0.f;
		DoubleGroundPoundAmount += 1;

		if(DoubleGroundPoundAmount == 1)
		{

		}
			
		if(DoubleGroundPoundAmount > 0)
		{
			StartCutscene.Broadcast();
			UHazeAkComponent::HazePostEventFireForget(DoubleGroundPoundAudioEvent, this.GetActorTransform());
		}
	}

	UFUNCTION()
	void WasGroundPounded(AHazePlayerCharacter Player)
	{
		if (Player.IsMay() && !BothPlayersHasGroundPounded)
		{
			MayTimer = 2.f;
		}
		
		else if (Player.IsCody() && !BothPlayersHasGroundPounded)
		{
			CodyTimer = 2.f;
		}

		if (!BothPlayersHasGroundPounded)
		{
			Player.PlayerHazeAkComp.HazePostEvent(SingleGroundPoundAudioEvent);
		}
		
		GroundPoundBlendValueCollision = -20;
		GroundPoundBlendValue = 0.6;
		DirtSplash.Activate(true);
		System::SetTimer(this, n"BendUpwards", 0.1f, false);
	}

	UFUNCTION()
	void BendUpwards()
	{
		GroundPoundBlendValue = 0;
		GroundPoundBlendValueCollision = 0;
	}

	UFUNCTION()
	void OnPlayerEnterTrigger(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(EnterAudioEvent);
		PlayerInt ++;
		if(PlayerInt == 1)
		{
			StandingOnBendValue = 0.4f;
			StandingOnBendValueCollision = -5;
		}
		else if(PlayerInt == 2)
		{
			StandingOnBendValue = 0.6f;
			StandingOnBendValueCollision = -10;
		}
	}
	UFUNCTION()
	void OnPlayerLeaveTrigger(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(LeaveAudioEvent);
		PlayerInt --;
		if(PlayerInt == 0)
		{
			StandingOnBendValue = 0.0f;
			StandingOnBendValueCollision = 0;
		}
		else if(PlayerInt == 1)
		{
			StandingOnBendValue = 0.4f;
			StandingOnBendValueCollision = -5;
		}
	}
}