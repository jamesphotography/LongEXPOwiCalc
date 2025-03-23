// 页面滚动平滑效果
document.addEventListener('DOMContentLoaded', function() {
    // 平滑滚动到锚点
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                window.scrollTo({
                    top: target.offsetTop - 80, // 考虑到固定导航栏的高度
                    behavior: 'smooth'
                });
            }
        });
    });

    // 监听页面滚动，添加导航栏阴影效果
    const header = document.querySelector('header');
    
    if (header) {
        window.addEventListener('scroll', () => {
            if (window.scrollY > 10) {
                header.classList.add('scrolled');
            } else {
                header.classList.remove('scrolled');
            }
        });
        
        // 初始化检查
        if (window.scrollY > 10) {
            header.classList.add('scrolled');
        }
    }
    
    // 添加页面加载动画效果
    document.body.classList.add('loaded');
});