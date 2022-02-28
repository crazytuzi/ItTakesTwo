import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;
import Vino.Movement.MovementSettings;
import Vino.Combustible.CombustibleComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Beetle.Movement.BeetleMovementDataComponent;
import Cake.LevelSpecific.Tree.Beetle.Health.BeetleHealthComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.LevelSpecific.Tree.Beetle.Animation.BeetleAnimationComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Peanuts.Audio.AudioStatics;
import Cake.Weapons.Sap.SapCustomAttachComponent;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockWaveComponent;

settings AIBeetleDefaultMovementSettings for UMovementSettings
{
	AIBeetleDefaultMovementSettings.MoveSpeed = 1000.f;
	AIBeetleDefaultMovementSettings.GravityMultiplier = 5.f;
	AIBeetleDefaultMovementSettings.WalkableSlopeAngle = 60.f;
	AIBeetleDefaultMovementSettings.StepUpAmount = 100.f;
}

UCLASS(Abstract)
class AAIBeetle : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = CharacterMesh0, AttachSocket = "Hips")
	USapCustomAttachComponent SapAttach;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIBeetleDefaultMovementSettings;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

   	default CapsuleComponent.SetCollisionProfileName(n"NPC");
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

    UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchHitResponseComp;

    UPROPERTY(DefaultComponent, ShowOnActor)
	UBeetleBehaviourComponent BehaviourComponent;

    UPROPERTY(DefaultComponent, ShowOnActor)
	UBeetleMovementDataComponent MoveDataComp;

    UPROPERTY(DefaultComponent, ShowOnActor)
	UBeetleHealthComponent HealthComp;

    UPROPERTY(DefaultComponent, ShowOnActor)
	UBeetleAnimationComponent AnimComp; 

    UPROPERTY(DefaultComponent, ShowOnActor)
	UBeetleShockwaveComponent ShockwaveComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BreathingStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BreathingStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitCharacterEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ObjectCollisionEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DamageTakenEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShockwaveEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShockwavePlayerHitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWingFlapEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwarmAudienceEvent;

	bool bCrumbsBlocked = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

        AddCapability(n"BeetleUpdateStateCapability");
		AddCapability(n"BeetleWalkMovementCapability");
		AddCapability(n"BeetleLeapMovementCapability");
		AddCapability(n"BeetleSlideToStopMovementCapability");
		AddCapability(n"BeetleDestroyObstaclesCapability");
		AddCapability(n"BeetleDefeatCapability");
		AddCapability(n"BeetleStartShockWaveCapability");
		AddCapability(n"BeetleUpdateShockWavesCapability");
		AddCapability(n"BeetleVOPlayerBarksCapability");

        AddCapability(n"BeetleBehaviourEntranceCapability");
        AddCapability(n"BeetleBehaviourFaceTargetCapability");
        AddCapability(n"BeetleBehaviourTelegraphCapability");
        AddCapability(n"BeetleBehaviourChargeCapability");
        AddCapability(n"BeetleBehaviourGoreCapability");
		AddCapability(n"BeetleBehaviourStompCapability");
		AddCapability(n"BeetleBehaviourPounceCapability");
		AddCapability(n"BeetleBehaviourMultiSlamCapability");
        AddCapability(n"BeetleBehaviourRecoverCapability");
        AddCapability(n"BeetleBehaviourStunnedCapability");

		SapResponseComp.OnMassAdded.AddUFunction(HealthComp, n"OnSapMassAdded");
		SapResponseComp.OnMassRemoved.AddUFunction(HealthComp, n"OnSapMassRemoved");
		SapResponseComp.OnSapExploded.AddUFunction(HealthComp, n"OnSapAttachedExplosion");
		SapResponseComp.OnSapExplodedProximity.AddUFunction(HealthComp, n"OnSapExplosionProximity");
		SapResponseComp.OnHitNonStick.AddUFunction(HealthComp, n"OnSapBounce");

		HealthComp.SetUnsappable();
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		HealthComp.OnTakeDamage.AddUFunction(BehaviourComponent, n"OnTakeDamage");
		BehaviourComponent.OnEntranceRoar.AddUFunction(HealthComp, n"ReadyForFight");
		BehaviourComponent.OnHitObstacle.AddUFunction(this, n"OnHitObstacle");
		BehaviourComponent.OnDefeat.AddUFunction(this, n"OnDefeat");
		BehaviourComponent.OnHitTarget.AddUFunction(this, n"OnHitTarget");
		BehaviourComponent.OnStartAttack.AddUFunction(this, n"OnStartAttack");
		BehaviourComponent.OnStopAttack.AddUFunction(this, n"OnStopAttack");

		HazeAkComp.HazePostEvent(BreathingStartEvent);
    }

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Pause crumb trail if disabled, since we might get enabled out of crumb sync (e.g. by cutscene)
		if (!bCrumbsBlocked)
		{
			BlockCrumbs(this);
			bCrumbsBlocked = true;
			BehaviourComponent.LogEvent("Blocking crumb trail");
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		// We can now resume crumb trail
		if (bCrumbsBlocked)
		{
			bCrumbsBlocked = false;
			UnblockCrumbs(this);
			BehaviourComponent.LogEvent("Unblocking crumb trail");
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnTakeDamage(float RemainingHealth, AHazePlayerCharacter Attacker, float BatchDamage, const FVector& DamageDir)
	{
		UHazeAkComponent::HazePostEventFireForget(DamageTakenEvent, ActorTransform);
	}

	UFUNCTION(BlueprintEvent)
	void OnHitObstacle()
	{
		UHazeAkComponent::HazePostEventFireForget(ObjectCollisionEvent, ActorTransform);
	}

	UFUNCTION(BlueprintEvent)
	void OnDefeat()
	{
		HazeAkComp.HazePostEvent(BreathingStopEvent);
		HazeAkComp.HazePostEvent(StopWingFlapEvent);
	}

	UFUNCTION()
	void OnStartAttack()
	{
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Beetle_IsAttacking", 1.f, 800);
	}

	UFUNCTION()
	void OnStopAttack()
	{
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Beetle_IsAttacking", 0.f, 1500);
	}

	UFUNCTION()
	void OnHitTarget()
	{
		UHazeAkComponent::HazePostEventFireForget(HitCharacterEvent, ActorTransform);
		UHazeAkComponent::HazePostEventFireForget(SwarmAudienceEvent, ActorTransform);
	}

	FString PrevStr = "";

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if EDITOR		
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			FString Str = (Game::GetMay().HasControl() ? " " : "") + "Beetle " + (HasControl() ? "CONTROL" : "  REMOTE") + "  " + (HealthComp.bSappable ? "   sappable" : "") + "  " + BehaviourComponent.State;
			if (Str == PrevStr)
				PrintToScreenScaled(Str, Scale = 1.5f);
			else
				PrintScaled(Str, Scale = 1.5f);
			PrevStr = Str;
			FLinearColor Color = HasControl() ? FLinearColor::Blue : FLinearColor::Gray;
			System::DrawDebugSphere(ActorLocation + FVector(0,0,1000), 200, 16, Color, 0.f, 10.f);
			Color = HealthComp.bSappable ? FLinearColor::Red : FLinearColor::Green;
			System::DrawDebugCylinder(ActorLocation, ActorLocation + FVector(0,0,800), 400, 12, Color, 0.f, 5.f);
		}
#endif

		float NormSpeed = HazeAudio::NormalizeRTPC01(MovementComponent.Velocity.Size(), 0.f, 2500.f);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Beetle_Speed", NormSpeed, 0.f);
	}
}
