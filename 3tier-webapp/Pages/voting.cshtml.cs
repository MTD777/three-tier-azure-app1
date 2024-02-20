using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Logging;
using _3tier_webapp.Data;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace _3tier_webapp.Pages
{
    public class VotingModel : PageModel
    {
        private readonly ILogger<VotingModel> _logger;
        private readonly VotingContext _context;

        public VotingModel(ILogger<VotingModel> logger, VotingContext context)
        {
            _logger = logger;
            _context = context;
            Question = "What compute offer rules?";
        }

        public string Question { get; set; }
        public List<VoteOption> Options => _context.VoteOptions.ToList();

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostCastVote(string optionText)
        {
            var option = _context.VoteOptions.FirstOrDefault(o => o.OptionText == optionText);
            if (option != null)
            {
                option.VoteCount++;
                await _context.SaveChangesAsync();
            }
            return Page();
        }
    }
}


// This works locally 

// namespace _3tier_webapp.Pages
// {
//     public class VotingModel : PageModel
//     {
//         private readonly ILogger<VotingModel> _logger;

//         public VotingModel(ILogger<VotingModel> logger)
//         {
//             _logger = logger;
//             Question = "What compute offer rules?";
//             Options = new List<VoteOption>
//             {
//                 new VoteOption { OptionText = "AKS", VoteCount = 0 },
//                 new VoteOption { OptionText = "Containers", VoteCount = 0 },
//                 new VoteOption { OptionText = "VMs", VoteCount = 0 },
//                 new VoteOption { OptionText = "Function Apps", VoteCount = 0 }
//             };
//         }

//         public string Question { get; set; }
//         public List<VoteOption> Options { get; set; }

//         public class VoteOption
//         {
//             public string OptionText { get; set; }
//             public int VoteCount { get; set; }
//         }

//         public void OnGet()
//         {
//         }

//         public IActionResult OnGetCastVote(string optionText)
//         {
//             var option = Options.FirstOrDefault(o => o.OptionText == optionText);
//             if (option != null)
//             {
//                 option.VoteCount++;
//             }
//             return Page();
//         }
//         public void OnPostCastVote(string optionText)
//         {
//             // Update the vote count for the selected option
//             var option = Options.FirstOrDefault(o => o.OptionText == optionText);
//             if (option != null)
//             {
//                 option.VoteCount++;
//             }
//         }
//     }
// }