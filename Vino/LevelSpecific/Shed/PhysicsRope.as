class APhysicsRopeActor : AHazeActor
{
    /*UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent SceneComponent;
    default SceneComponent.bVisualizeComponent = true;*/

    UPROPERTY(DefaultComponent, RootComponent)
    USplineComponent SplineComponent;
    //default SplineComponent.Mobility = EComponentMobility::Static;

    UPROPERTY(Category = "Arrays")
    TArray<USphereComponent> CollisionSphereComponents;
    UPROPERTY(Category = "Arrays")
    TArray<UPhysicsConstraintComponent> ConstraintComponents;
    UPROPERTY(Category = "Arrays")
    TArray<USplineMeshComponent> SplineMeshComponents;

    UPROPERTY(Category = "Spline Mesh Properties")
    UStaticMesh StartMesh;
    UPROPERTY(Category = "Spline Mesh Properties")
    UStaticMesh EndMesh;
    UPROPERTY(Category = "Spline Mesh Properties")
    UStaticMesh BodyMesh;

    UPROPERTY(Category = "Cable Properties")
    int SphereCount = 20;
    UPROPERTY(Category = "Cable Properties")
    float ExtraSphereGap = 0;
    UPROPERTY(Category = "Cable Properties")
    float SphereRadius = 15;
    UPROPERTY(Category = "Cable Properties")
    float SphereLinearDamping = 1; //3
    UPROPERTY(Category = "Cable Properties")
    float SphereAngularDamping = 1.f; //6.5
    UPROPERTY(Category = "Cable Properties")
    float SphereMassOverride = -1;

    UPROPERTY(Category = "Constraint Properties")
    float AngularSwing1Limit = 50.f;
    UPROPERTY(Category = "Constraint Properties")
    float AngularSwing2Limit = 50.f;
    UPROPERTY(Category = "Constraint Properties")
    float AngularTwistLimit = 50.f; 


    UPROPERTY(Category = "Debug")
    bool DebugSphereComponents = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
        //AddCollisionSpheres();
        //AddPhysicsConstraints();
        // Spline?
        //AddSplineMeshes();
    }

    void AddCollisionSpheres()
    {
        if (CollisionSphereComponents.Num() != 0)
        {
            CollisionSphereComponents.Empty();
        }

        for (int Index = 0, Count = SphereCount; Index < Count; ++Index)
        {
            // Create and add the sphere
            FName CompName("CollisionSphere " + Index);
            CollisionSphereComponents.Add(USphereComponent(this, CompName));
            // Settings for the sphere
            USphereComponent Loc_SphereComponent = CollisionSphereComponents[Index];
            Loc_SphereComponent.SetRelativeLocation(FVector(Index * ((-SphereRadius * 2) - ExtraSphereGap), 0, 0));
            Loc_SphereComponent.SetSimulatePhysics(true);
            Loc_SphereComponent.SetCollisionProfileName(n"PhysicsActor");
            Loc_SphereComponent.SetUseCCD(true);
            Loc_SphereComponent.SetSphereRadius(SphereRadius);
            if (SphereMassOverride != -1)
                Loc_SphereComponent.SetMassOverrideInKg(n"None", SphereMassOverride, true);
            Loc_SphereComponent.SetLinearDamping(SphereLinearDamping);
            Loc_SphereComponent.SetLinearDamping(SphereAngularDamping);
        }
    }

    void AddPhysicsConstraints()
    {
        if (CollisionSphereComponents.Num() > 1)
        {
            if (ConstraintComponents.Num() != 0)
                ConstraintComponents.Empty();

            for (int Index = 0, Count = GetCollisionSphereLastIndex(); Index < Count; ++Index)
            {                            
                
                //USphereComponent Loc_CollisionSphere = CollisionSphereComponents[Index];
                
                // Add constraint component
                FName Loc_CompName("Constraint " + Index + "/" + (Index + 1));
                ConstraintComponents.Add(UPhysicsConstraintComponent(this, Loc_CompName));
                UPhysicsConstraintComponent Loc_ConstraintComponent = ConstraintComponents[Index];

                FVector Loc_ConstraintLocation = (CollisionSphereComponents[Index].GetWorldLocation() + CollisionSphereComponents[Index + 1].GetWorldLocation()) / 2;
                Loc_ConstraintComponent.SetWorldLocation(Loc_ConstraintLocation);
                Loc_ConstraintComponent.SetConstrainedComponents(CollisionSphereComponents[Index], n"None",CollisionSphereComponents[Index + 1], n"None");
                Loc_ConstraintComponent.SetAngularSwing1Limit(EAngularConstraintMotion::ACM_Limited, 50.f);
                Loc_ConstraintComponent.SetAngularSwing2Limit(EAngularConstraintMotion::ACM_Limited, 50.f);
                Loc_ConstraintComponent.SetAngularTwistLimit(EAngularConstraintMotion::ACM_Limited, 50.f);

                

                //USphereComponent(this, Loc_CompName);

                //UPhysicsConstraintComponent Loc_Constraint 
                //= Loc_CollisionSphere.AddPhysicsConstraints();
            }
        }
    }

    void AddSplineMeshes()
    {
        if (CollisionSphereComponents.Num() > 1)
        {
            if (SplineMeshComponents.Num() != 0)
                SplineMeshComponents.Empty();

            for (int Index = 0, Count = GetCollisionSphereLastIndex(); Index < Count; ++Index)
            {    
                FName Loc_CompName("SplineMesh " + Index + "/" + (Index + 1));
                SplineMeshComponents.Add(USplineMeshComponent(this, Loc_CompName));
                USplineMeshComponent Loc_SplineMeshComponent = SplineMeshComponents[Index];

                //Loc_SplineMeshComponent.SetWorldLocation(Loc_ConstraintLocation);
                if (BodyMesh != nullptr)
                    Loc_SplineMeshComponent.SetStaticMesh(BodyMesh);
                    
                Loc_SplineMeshComponent.SetStartAndEnd(CollisionSphereComponents[Index].RelativeLocation, GetActorForwardVector(), CollisionSphereComponents[Index + 1].RelativeLocation, GetActorForwardVector(), true);
            }
        }
    }     

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
    {
        DrawDebugSpheres();
    }

    UFUNCTION(BlueprintPure)
    int GetCollisionSphereLastIndex()
    {
        return CollisionSphereComponents.Num() - 1;
    }

    UFUNCTION()
    void DrawDebugSpheres()
    {
        if (DebugSphereComponents)
        {
            for (USphereComponent Loc_CollisionSphere : CollisionSphereComponents)
            {
                if (Loc_CollisionSphere != nullptr)
                    System::DrawDebugSphere(Loc_CollisionSphere.GetWorldLocation(), Loc_CollisionSphere.SphereRadius, 10, FLinearColor::Red, 0, 0.5f);
            }
        }
    }
}