UCLASS(HideCategories = "Sockets Rendering Cooking Tags LOD Activation Collision ComponentReplication AssetUserData")
class UProjectileMove : UActorComponent
{
    UPROPERTY(Category = "Projectile Movement")
    FVector Velocity;

    UPROPERTY(Category = "Projectile Movement")
    float Gravity = 980.f;

    UFUNCTION(Category = "Projectile Movement", meta = (ReturnDisplayName = "Movement Delta"))
    FVector UpdateProjectileMovement(float DeltaTime)
    {
        FVector GravityAcceleration = FVector(0.f, 0.f, -Gravity);
        FVector MovementDelta = Velocity * DeltaTime + GravityAcceleration * DeltaTime * DeltaTime * 0.5f;

        Velocity += GravityAcceleration * DeltaTime;
        return MovementDelta;
    }
}

struct FProjectileMovementData
{
    UPROPERTY(Category = "Projectile|Movement")
    FVector Velocity;

    UPROPERTY(Category = "Projectile|Movement")
    float Gravity = 980.f;
}

struct FProjectileUpdateData
{
    UPROPERTY(Category = "Projectile|Movement")
    FProjectileMovementData UpdatedMovementData;

    UPROPERTY(Category = "Projectile|Movement")
    FVector DeltaMovement;
}

UFUNCTION(Category = "Projectile|Movement", meta = (ReturnDisplayName = "Update Data"))
FProjectileUpdateData CalculateProjectileMovement(FProjectileMovementData Data, float DeltaTime)
{
    FVector Velocity = Data.Velocity;
    FVector Acceleration = FVector(0.f, 0.f, -Data.Gravity);

    FVector DeltaMove = Velocity * DeltaTime + Acceleration * DeltaTime * DeltaTime * 0.5;

    FProjectileUpdateData Result;
    Result.UpdatedMovementData.Velocity = Velocity + Acceleration * DeltaTime;
    Result.DeltaMovement = DeltaMove;

    return Result;
}