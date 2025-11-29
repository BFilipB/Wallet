using FluentValidation;
using Wallet.Shared;

namespace Wallet.Api.Validators;

public class TopUpRequestValidator : AbstractValidator<TopUpRequest>
{
    public TopUpRequestValidator()
    {
        RuleFor(x => x.PlayerId)
            .NotEmpty()
            .WithMessage("PlayerId is required")
            .MaximumLength(100)
            .WithMessage("PlayerId cannot exceed 100 characters");

        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .WithMessage("Amount must be greater than zero")
            .LessThanOrEqualTo(1000000)
            .WithMessage("Amount cannot exceed 1,000,000");

        RuleFor(x => x.ExternalRef)
            .NotEmpty()
            .WithMessage("ExternalRef is required")
            .MaximumLength(200)
            .WithMessage("ExternalRef cannot exceed 200 characters");
    }
}
