import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.Hopscotch.FidgetspinnerLandingpad;

class AFidgetSpinner : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBoxComponent BoxCollision;
    default BoxCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    UHazeTriggerComponent InteractionCollision;

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USphereComponent SphereCollision01;
    default SphereCollision01.RelativeLocation = FVector(-310.f, -540.f, 0.f);
    default SphereCollision01.SphereRadius = 160.f;

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USphereComponent SphereCollision02;
    default SphereCollision02.RelativeLocation = FVector(600.f, 0.f, 0.f);
    default SphereCollision02.SphereRadius = 160.f;

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USphereComponent SphereCollision03;
    default SphereCollision03.RelativeLocation = FVector(-310.f, 540.f, 0.f);
    default SphereCollision03.SphereRadius = 160.f;

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USceneComponent ButtonMashWidgetLocation01;
    default ButtonMashWidgetLocation01.RelativeLocation = FVector(-310.f, -540.f, 60.f);

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USceneComponent ButtonMashWidgetLocation02;
    default ButtonMashWidgetLocation02.RelativeLocation = FVector(600.f, 0.f, 60.f);

    UPROPERTY(DefaultComponent, Attach = BoxCollision)
    USceneComponent ButtonMashWidgetLocation03;
    default ButtonMashWidgetLocation03.RelativeLocation = FVector(-310.f, 540.f, 60.f);

    UPROPERTY()
	UNiagaraSystem ExplosionEffect;

    UPROPERTY()
    float GoingBackForce;
    default GoingBackForce = 1.f;

    UPROPERTY()
    float ProgressionForce;
    default ProgressionForce = 0.3f;

    UPROPERTY()
    float ZForceMultiplier;
    default ZForceMultiplier = 30000.f;

	UPROPERTY()
	float FidgetSpinnerGravity;
	default FidgetSpinnerGravity = 450.f;

    TArray<UPrimitiveComponent> SphereCollisionArray;
    TArray<USceneComponent> WidgetLocationArray;
    UButtonMashProgressHandle ButtonMashHandle;
    AHazePlayerCharacter PlayerChargingRef;
    AHazePlayerCharacter PlayerOnFidgetSpinner;
    float ButtonMashProgression;
    float Progression;    

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetupTriggerProperties(InteractionCollision);

        FHazeTriggerActivationDelegate InteractionDelegate;
		InteractionDelegate.BindUFunction(this, n"OnInteractionTriggerActivated");
		InteractionCollision.AddActivationDelegate(InteractionDelegate);

        // ButtonMash Collision Setup
        SphereCollision01.OnComponentBeginOverlap.AddUFunction(this, n"SphereOnBeginOverlap");
        SphereCollision02.OnComponentBeginOverlap.AddUFunction(this, n"SphereOnBeginOverlap");
        SphereCollision03.OnComponentBeginOverlap.AddUFunction(this, n"SphereOnBeginOverlap");

        SphereCollision01.OnComponentEndOverlap.AddUFunction(this, n"SphereOnEndOverlap");
        SphereCollision02.OnComponentEndOverlap.AddUFunction(this, n"SphereOnEndOverlap");
        SphereCollision03.OnComponentEndOverlap.AddUFunction(this, n"SphereOnEndOverlap");

        // Add Sphere Collisions to array
        SphereCollisionArray.Add(SphereCollision01);
        SphereCollisionArray.Add(SphereCollision02);
        SphereCollisionArray.Add(SphereCollision03);

        // Add Scene Components to array
        WidgetLocationArray.Add(ButtonMashWidgetLocation01);
        WidgetLocationArray.Add(ButtonMashWidgetLocation02);
        WidgetLocationArray.Add(ButtonMashWidgetLocation03);

        //EnableSpinUpInteractionCollision(false);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if (ButtonMashHandle != nullptr)
        {    
            Progression = FMath::Clamp(Progression - (GoingBackForce * ActorDeltaSeconds), 0.f, 1.f);
            Progression = FMath::Clamp(Progression + (ButtonMashHandle.MashRateControlSide * ProgressionForce * ActorDeltaSeconds), 0.f, 1.f);
            ButtonMashHandle.Progress = Progression;

            if (Progression >= 1.f)
            {
                DetachWidgetFromPlayer();
                
                if(PlayerOnFidgetSpinner != nullptr)
                {
                    PlayerOnFidgetSpinner.SetCapabilityActionState(n"FidgetShouldSpin", EHazeActionState::Active);
                }
            }
        }
    }

    // Setup Trigger Properties for interaction collision
    void SetupTriggerProperties(UHazeTriggerComponent TriggerComponent)
    {
        FHazeShapeSettings ActionShape;
		ActionShape.SphereRadius = 350.f;
		ActionShape.Type = EHazeShapeType::Sphere;

		FHazeShapeSettings FocusShape;
		FocusShape.Type = EHazeShapeType::Sphere;
		FocusShape.SphereRadius = 1000.f;

		FTransform ActionTransform;
		ActionTransform.SetScale3D(FVector(1.f));

		FHazeDestinationSettings MovementSettings;
        MovementSettings.InitializeSmoothTeleportWithSpeed();

		FHazeActivationSettings ActivationSettings;
		ActivationSettings.ActivationType = EHazeActivationType::Action;

		FHazeTriggerVisualSettings VisualSettings;
		VisualSettings.VisualOffset.Location = FVector(0.f, 0.f, 125.f);

		TriggerComponent.AddActionShape(ActionShape, ActionTransform);
		TriggerComponent.AddFocusShape(FocusShape, ActionTransform);
		TriggerComponent.AddMovementSettings(MovementSettings);
		TriggerComponent.AddActivationSettings(ActivationSettings);
		TriggerComponent.SetVisualSettings(VisualSettings);
    }

    // Called when Spinner is interacted with
    UFUNCTION()
    void OnInteractionTriggerActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {
        PlayerOnFidgetSpinner = Player;
        PlayerOnFidgetSpinner.SetCapabilityAttributeObject(n"FidgetSpinner", this);
        PlayerOnFidgetSpinner.SetCapabilityActionState(n"PlayerOnFidgetSpinner", EHazeActionState::Active);
        PlayerOnFidgetSpinner.SetCapabilityAttributeValue(n"ZForceMultiplier", ZForceMultiplier);
		PlayerOnFidgetSpinner.SetCapabilityAttributeValue(n"Gravity", FidgetSpinnerGravity);
        PlayerOnFidgetSpinner.SetCapabilityActionState(n"FidgetShouldSpin", EHazeActionState::Active);
        //EnableSpinUpInteractionCollision(true);
    }

    void EnableInteractionCollision(bool bShouldBeActive)
    {
        if (bShouldBeActive)
            InteractionCollision.Enable(n"");

        else
            InteractionCollision.Disable(n"");
    }

    void EnableSpinUpInteractionCollision(bool bShouldActivate)
    {
        for (UPrimitiveComponent Comp : SphereCollisionArray)
        {
            ECollisionEnabled Collision = bShouldActivate == true ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
            Comp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        }
    }

    void PlayerHoppedOffFidgetSpinner()
    {
        PlayerOnFidgetSpinner.SetCapabilityActionState(n"FidgetShouldSpin", EHazeActionState::Inactive);
        PlayerOnFidgetSpinner = nullptr;
        //EnableSpinUpInteractionCollision(false);
    }

    UFUNCTION()
    void SphereOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
        if (PlayerChargingRef == nullptr)
        {
            if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
            {
                PlayerChargingRef = Cast<AHazePlayerCharacter>(OtherActor);
                //AttachWidgetToPlayer(OverlappedComponent);
            }        
        }
    }

    UFUNCTION()
    void SphereOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        if (PlayerChargingRef != nullptr)
        {
            if (OtherActor == PlayerChargingRef)
            {
                //DetachWidgetFromPlayer();
            }
        }
    }

    void AttachWidgetToPlayer(AHazePlayerCharacter Player)
    {
        USceneComponent AttachComponent;
        //AttachComponent = WidgetLocationArray[SphereCollisionArray.FindIndex(OverlappedComponent)];
        AttachComponent = WidgetLocationArray[0];  
        ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, AttachComponent, n"", FVector::ZeroVector);
    }

    void DetachWidgetFromPlayer()
    {
        StopButtonMash(ButtonMashHandle);
        PlayerChargingRef.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
        PlayerChargingRef = nullptr;
        Progression = 0.f;
        ButtonMashHandle = nullptr;
    }

    bool LandedOnLandingpad()
    {
        TArray<AActor> OverlapArray;
        bool bOverlappingLandingpad = false;
        BoxCollision.GetOverlappingActors(OverlapArray);

        for (AActor Actor : OverlapArray)
        {
            if (Cast<AFidgetspinnerLandingpad>(Actor) != nullptr)
            {
                bOverlappingLandingpad = true;
                break;
            }
        }
        return bOverlappingLandingpad;
    }

    void DestroyFidgetSpinner(bool bShouldPlayFX)
    {
		if (bShouldPlayFX)
        	Niagara::SpawnSystemAtLocation(ExplosionEffect, GetActorLocation(), GetActorRotation());
        
		DestroyActor();
    }
}